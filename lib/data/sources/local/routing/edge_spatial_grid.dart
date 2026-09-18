import 'dart:math';
import '../../../../domain/routing/models/snap_result.dart';
import 'csr_graph.dart';

class EdgeSpatialGrid {
  static const double cellSize = 0.0025; // ~275 meters
  static const double earthRadius = 6371000.0;

  final CsrGraph graph;
  final Map<int, List<int>> _grid = {};

  EdgeSpatialGrid(this.graph) {
    _buildIndex();
  }

  static int _cellKey(int cx, int cy) {
    // 32-bit pack: cx in lower 16 bits, cy in upper 16 bits
    return ((cy & 0xFFFF) << 16) | (cx & 0xFFFF);
  }

  void _buildIndex() {
    for (int u = 0; u < graph.nodeCount; u++) {
      final start = graph.getEdgeStart(u);
      final end = graph.getEdgeEnd(u);
      final latA = graph.getNodeLat(u);
      final lonA = graph.getNodeLon(u);

      for (int i = start; i < end; i++) {
        final v = graph.getEdgeTarget(i);
        if (u < v) {
          // Only index canonical direction
          final latB = graph.getNodeLat(v);
          final lonB = graph.getNodeLon(v);

          final minLat = min(latA, latB);
          final maxLat = max(latA, latB);
          final minLon = min(lonA, lonB);
          final maxLon = max(lonA, lonB);

          final minCx = (minLon / cellSize).floor();
          final maxCx = (maxLon / cellSize).floor();
          final minCy = (minLat / cellSize).floor();
          final maxCy = (maxLat / cellSize).floor();

          for (int cx = minCx; cx <= maxCx; cx++) {
            for (int cy = minCy; cy <= maxCy; cy++) {
              final key = _cellKey(cx, cy);
              final list = _grid[key] ??= [];
              list.add(i); // store directed edge index
            }
          }
        }
      }
    }
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Projects point P(lat, lon) onto the nearest walkable street segment.
  /// If nearest segment exceeds [thresholdMeters], returns [SnapStatus.snapNotFound].
  SnapResult snapToSegment(
    double lat,
    double lon, {
    double thresholdMeters = 50.0,
  }) {
    final userCx = (lon / cellSize).floor();
    final userCy = (lat / cellSize).floor();

    // Search cells in concentric radii (radius 1 = 9 cells, radius 2 = 25 cells)
    final testedEdgeIndices = <int>{};
    double bestDist = double.infinity;
    double bestSnappedLat = lat;
    double bestSnappedLon = lon;
    double bestT = 0.0;
    int bestEdgeIdx = -1;
    int bestU = -1;
    int bestV = -1;
    int bestEdgeId = -1;

    final cosLat = cos(lat * (pi / 180.0));
    final metersPerDegLon = 111320.0 * cosLat;
    const metersPerDegLat = 110540.0;

    for (int r = 0; r <= 2; r++) {
      for (int dx = -r; dx <= r; dx++) {
        for (int dy = -r; dy <= r; dy++) {
          if (r > 0 && dx.abs() < r && dy.abs() < r) {
            continue; // avoid inner ring
          }
          final key = _cellKey(userCx + dx, userCy + dy);
          final edges = _grid[key];
          if (edges == null) continue;

          for (final edgeIdx in edges) {
            if (!testedEdgeIndices.add(edgeIdx)) continue;

            final u = _findSourceNode(edgeIdx);
            final v = graph.getEdgeTarget(edgeIdx);
            final latA = graph.getNodeLat(u);
            final lonA = graph.getNodeLon(u);
            final latB = graph.getNodeLat(v);
            final lonB = graph.getNodeLon(v);

            // Local planar projection around user point
            final ax = (lonA - lon) * metersPerDegLon;
            final ay = (latA - lat) * metersPerDegLat;
            final bx = (lonB - lon) * metersPerDegLon;
            final by = (latB - lat) * metersPerDegLat;

            final vx = bx - ax;
            final vy = by - ay;
            final vLenSq = vx * vx + vy * vy;

            double t = 0.0;
            if (vLenSq > 0.0001) {
              t = (-(ax * vx + ay * vy)) / vLenSq;
              if (t < 0.0) t = 0.0;
              if (t > 1.0) t = 1.0;
            }

            final projLat = latA + t * (latB - latA);
            final projLon = lonA + t * (lonB - lonA);
            final dist = haversineMeters(lat, lon, projLat, projLon);

            if (dist < bestDist) {
              bestDist = dist;
              bestSnappedLat = projLat;
              bestSnappedLon = projLon;
              bestT = t;
              bestEdgeIdx = edgeIdx;
              bestU = u;
              bestV = v;
              bestEdgeId = graph.getEdgeId(edgeIdx);
            }
          }
        }
      }
      if (bestDist <= thresholdMeters) {
        break; // Early exit if we found a valid snap within threshold
      }
    }

    if (bestDist > thresholdMeters || bestEdgeIdx == -1) {
      return SnapResult.notFound(
        lat: lat,
        lon: lon,
        thresholdMeters: thresholdMeters,
      );
    }

    return SnapResult(
      status: SnapStatus.success,
      originalLat: lat,
      originalLon: lon,
      snappedLat: bestSnappedLat,
      snappedLon: bestSnappedLon,
      distanceMeters: bestDist,
      edgeId: bestEdgeId,
      uNodeIndex: bestU,
      vNodeIndex: bestV,
      projectionT: bestT,
      segmentLengthMeters: graph.getEdgeWeightMeters(bestEdgeIdx),
      thresholdMeters: thresholdMeters,
    );
  }

  // Binary search to find source node u for an edge index
  int _findSourceNode(int edgeIndex) {
    int low = 0;
    int high = graph.nodeCount - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final start = graph.getEdgeStart(mid);
      final end = graph.getEdgeEnd(mid);
      if (edgeIndex < start) {
        high = mid - 1;
      } else if (edgeIndex >= end) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return low;
  }
}
