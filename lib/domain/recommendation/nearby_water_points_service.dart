import '../../core/utils/geo_utils.dart';
import '../../data/models/water_point.dart';
import '../routing/repositories/routing_repository.dart';
import '../../data/repositories/local_routing_repository.dart';

/// Service that ranks water points by proximity from the user's real location.
///
/// Uses Haversine geodetic distance as a pre-filter across the full 433-point
/// Lima/Callao catalog, and computes exact pedestrian network routes (A* via CSR
/// graph with 50 m edge snapping) for the closest candidates without blocking UI.
class NearbyWaterPointsService {
  final RoutingRepository _routingEngine;

  NearbyWaterPointsService({RoutingRepository? routingEngine})
    : _routingEngine = routingEngine ?? LocalRoutingRepository.instance;

  /// Fast geodetic pre-filter using Haversine formula.
  ///
  /// Marks all calculated distances as [isDistanceApproximate: true] so the UI
  /// never mislabels a straight-line geodetic distance as real walking distance.
  List<WaterPoint> rankByGeodesicDistance({
    required List<WaterPoint> points,
    required double originLat,
    required double originLon,
  }) {
    final list = points.map((p) {
      final dist = GeoUtils.calculateDistanceMeters(
        originLat,
        originLon,
        p.lat,
        p.lon,
      );
      return p.copyWith(distMeters: dist, isDistanceApproximate: true);
    }).toList();

    list.sort((a, b) => (a.distMeters ?? 0).compareTo(b.distMeters ?? 0));
    return list;
  }

  /// Full ranking: geodetic pre-filtering + exact pedestrian graph routing.
  ///
  /// Computes exact A* pedestrian paths for the top [maxCandidatesToRoute]
  /// closest water points. When an exact route is found within the 50 m snap
  /// threshold, updates [distMeters] with the real street walking distance and
  /// sets [isDistanceApproximate: false].
  Future<List<WaterPoint>> rankAndRouteNearest({
    required List<WaterPoint> points,
    required double originLat,
    required double originLon,
    int maxCandidatesToRoute = 10,
    Set<int>? blockedEdgeIds,
  }) async {
    // 1. Initial geodetic pre-filtering
    final geodeticRanked = rankByGeodesicDistance(
      points: points,
      originLat: originLat,
      originLon: originLon,
    );

    if (geodeticRanked.isEmpty) return [];

    // If routing engine is not initialized or candidate count is 0, return geodetic rank
    if (!_routingEngine.isInitialized || maxCandidatesToRoute <= 0) {
      return geodeticRanked;
    }

    final candidateCount = geodeticRanked.length < maxCandidatesToRoute
        ? geodeticRanked.length
        : maxCandidatesToRoute;

    final candidates = geodeticRanked.sublist(0, candidateCount);
    final remaining = geodeticRanked.sublist(candidateCount);

    // 2. Compute exact pedestrian routing for candidates
    final List<WaterPoint> routedCandidates = [];
    for (final point in candidates) {
      try {
        final route = _routingEngine.routeToPoint(
          originLat: originLat,
          originLon: originLon,
          destinationLat: point.lat,
          destinationLon: point.lon,
          snapThresholdMeters: 50.0,
          blockedEdgeIds: blockedEdgeIds,
        );

        if (route != null && route.isSuccess) {
          routedCandidates.add(
            point.copyWith(
              distMeters: route.distanceMeters.round(),
              isDistanceApproximate: false,
            ),
          );
        } else {
          // Route could not snap or find path within 50m; keep geodetic with approximate flag
          routedCandidates.add(point);
        }
      } catch (_) {
        routedCandidates.add(point);
      }
    }

    // 3. Sort routed candidates by their final distance
    routedCandidates.sort(
      (a, b) => (a.distMeters ?? 0).compareTo(b.distMeters ?? 0),
    );

    // 4. Combine top routed candidates + remaining approximate points
    return [...routedCandidates, ...remaining];
  }
}
