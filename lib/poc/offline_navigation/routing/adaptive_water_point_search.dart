import '../models/route_result.dart';
import '../spatial/edge_spatial_grid.dart';
import 'astar_router.dart';

class AdaptiveSearchResult {
  final Map<String, dynamic>? winnerPoint;
  final RouteResult? winnerRoute;
  final Map<String, dynamic>? haversineWinnerPoint;
  final double haversineWinnerHaversineDistance;
  final double haversineWinnerRouteDistance;
  final int candidatesRoutedCount;
  final int totalCandidatesCount;
  final double stoppingHaversineDistance;
  final double totalSearchTimeMs;

  const AdaptiveSearchResult({
    required this.winnerPoint,
    required this.winnerRoute,
    required this.haversineWinnerPoint,
    required this.haversineWinnerHaversineDistance,
    required this.haversineWinnerRouteDistance,
    required this.candidatesRoutedCount,
    required this.totalCandidatesCount,
    required this.stoppingHaversineDistance,
    required this.totalSearchTimeMs,
  });

  bool get hasDivergence {
    if (winnerPoint == null || haversineWinnerPoint == null) return false;
    return winnerPoint!['water_point_id'] !=
        haversineWinnerPoint!['water_point_id'];
  }

  double get savingsMeters {
    if (!hasDivergence ||
        haversineWinnerRouteDistance.isInfinite ||
        winnerRoute == null) {
      return 0.0;
    }
    return haversineWinnerRouteDistance - winnerRoute!.distanceMeters;
  }
}

class AdaptiveWaterPointSearch {
  final AstarRouter router;

  const AdaptiveWaterPointSearch(this.router);

  /// Performs an adaptive search over water points using geodesic lower-bound early stopping.
  ///
  /// Mathematical Stopping Rule:
  /// Any pedestrian path from origin O to candidate P_k satisfies:
  ///   D_route(O, P_k) >= haversine(O, P_k)
  /// Therefore, if candidates are ordered by ascending Haversine distance, and we encounter
  /// a candidate with haversine(O, P_k) >= bestRouteDistance, NO subsequent candidate P_j (j >= k)
  /// can mathematically produce a route shorter than bestRouteDistance.
  AdaptiveSearchResult search({
    required double originLat,
    required double originLon,
    required List<Map<String, dynamic>> waterPoints,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  }) {
    final stopwatch = Stopwatch()..start();

    if (waterPoints.isEmpty) {
      return const AdaptiveSearchResult(
        winnerPoint: null,
        winnerRoute: null,
        haversineWinnerPoint: null,
        haversineWinnerHaversineDistance: double.infinity,
        haversineWinnerRouteDistance: double.infinity,
        candidatesRoutedCount: 0,
        totalCandidatesCount: 0,
        stoppingHaversineDistance: 0.0,
        totalSearchTimeMs: 0.0,
      );
    }

    // 1. Precompute Haversine distances to all candidates
    final candidates =
        waterPoints.map((p) {
          final lat = (p['latitude'] as num).toDouble();
          final lon = (p['longitude'] as num).toDouble();
          final h = EdgeSpatialGrid.haversineMeters(
            originLat,
            originLon,
            lat,
            lon,
          );
          return {'point': p, 'lat': lat, 'lon': lon, 'haversine_m': h};
        }).toList()..sort(
          (a, b) => (a['haversine_m'] as double).compareTo(
            b['haversine_m'] as double,
          ),
        );

    final haversineWinner = candidates.first;
    final haversineWinnerPoint =
        haversineWinner['point'] as Map<String, dynamic>;
    final haversineWinnerH = haversineWinner['haversine_m'] as double;

    double bestRouteDistance = double.infinity;
    RouteResult? bestRoute;
    Map<String, dynamic>? bestPoint;
    double haversineWinnerWalkDist = double.infinity;
    int routedCount = 0;
    double stoppingHaversine = double.infinity;

    // 2. Adaptive iteration with lower-bound stopping condition
    for (int i = 0; i < candidates.length; i++) {
      final cand = candidates[i];
      final candH = cand['haversine_m'] as double;

      // Exact mathematical stopping rule:
      if (candH >= bestRouteDistance) {
        stoppingHaversine = candH;
        break;
      }

      final pLat = cand['lat'] as double;
      final pLon = cand['lon'] as double;

      final route = router.route(
        originLat: originLat,
        originLon: originLon,
        destinationLat: pLat,
        destinationLon: pLon,
        snapThresholdMeters: snapThresholdMeters,
        blockedEdgeIds: blockedEdgeIds,
      );
      routedCount++;

      if (i == 0) {
        haversineWinnerWalkDist = route.isSuccess
            ? route.distanceMeters
            : double.infinity;
      }

      if (route.isSuccess) {
        if (route.distanceMeters < bestRouteDistance) {
          bestRouteDistance = route.distanceMeters;
          bestRoute = route;
          bestPoint = cand['point'] as Map<String, dynamic>;
        }
      }
    }

    stopwatch.stop();

    return AdaptiveSearchResult(
      winnerPoint: bestPoint,
      winnerRoute: bestRoute,
      haversineWinnerPoint: haversineWinnerPoint,
      haversineWinnerHaversineDistance: haversineWinnerH,
      haversineWinnerRouteDistance: haversineWinnerWalkDist,
      candidatesRoutedCount: routedCount,
      totalCandidatesCount: waterPoints.length,
      stoppingHaversineDistance: stoppingHaversine,
      totalSearchTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }

  /// Exhaustive search oracle: evaluates ALL water points to verify ground truth optimality.
  /// Strictly used as a test control oracle to prove adaptive early stopping accuracy.
  AdaptiveSearchResult searchExhaustive({
    required double originLat,
    required double originLon,
    required List<Map<String, dynamic>> waterPoints,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  }) {
    final stopwatch = Stopwatch()..start();

    final candidates =
        waterPoints.map((p) {
          final lat = (p['latitude'] as num).toDouble();
          final lon = (p['longitude'] as num).toDouble();
          final h = EdgeSpatialGrid.haversineMeters(
            originLat,
            originLon,
            lat,
            lon,
          );
          return {'point': p, 'lat': lat, 'lon': lon, 'haversine_m': h};
        }).toList()..sort(
          (a, b) => (a['haversine_m'] as double).compareTo(
            b['haversine_m'] as double,
          ),
        );

    final haversineWinner = candidates.first;
    final haversineWinnerPoint =
        haversineWinner['point'] as Map<String, dynamic>;
    final haversineWinnerH = haversineWinner['haversine_m'] as double;

    double bestRouteDistance = double.infinity;
    RouteResult? bestRoute;
    Map<String, dynamic>? bestPoint;
    double haversineWinnerWalkDist = double.infinity;
    int routedCount = 0;

    for (int i = 0; i < candidates.length; i++) {
      final cand = candidates[i];
      final pLat = cand['lat'] as double;
      final pLon = cand['lon'] as double;

      final route = router.route(
        originLat: originLat,
        originLon: originLon,
        destinationLat: pLat,
        destinationLon: pLon,
        snapThresholdMeters: snapThresholdMeters,
        blockedEdgeIds: blockedEdgeIds,
      );
      routedCount++;

      if (i == 0) {
        haversineWinnerWalkDist = route.isSuccess
            ? route.distanceMeters
            : double.infinity;
      }

      if (route.isSuccess) {
        if (route.distanceMeters < bestRouteDistance) {
          bestRouteDistance = route.distanceMeters;
          bestRoute = route;
          bestPoint = cand['point'] as Map<String, dynamic>;
        }
      }
    }

    stopwatch.stop();

    return AdaptiveSearchResult(
      winnerPoint: bestPoint,
      winnerRoute: bestRoute,
      haversineWinnerPoint: haversineWinnerPoint,
      haversineWinnerHaversineDistance: haversineWinnerH,
      haversineWinnerRouteDistance: haversineWinnerWalkDist,
      candidatesRoutedCount: routedCount,
      totalCandidatesCount: waterPoints.length,
      stoppingHaversineDistance: double.infinity,
      totalSearchTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }
}
