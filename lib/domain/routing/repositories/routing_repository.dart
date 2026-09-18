import '../models/route_result.dart';
import '../models/snap_result.dart';

/// Result of an adaptive search over all water points to find
/// the closest reachable one via the pedestrian walking graph.
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

/// Abstract contract for the offline pedestrian routing engine.
///
/// Implementations provide the concrete graph loading, spatial indexing,
/// and A* pathfinding logic. This abstraction allows the presentation
/// layer to remain independent of the specific routing implementation.
abstract class RoutingRepository {
  /// Whether the routing engine has been initialized with graph data.
  bool get isInitialized;

  /// The MapLibre style JSON string for offline map rendering, or null
  /// if not yet initialized.
  String? get styleString;

  /// The loaded water points catalog (433 official SEDAPAL points).
  List<Map<String, dynamic>> get waterPoints;

  /// Cold start timing metrics for diagnostics.
  Map<String, int> get coldStartTimestamps;

  /// Initializes the routing engine: loads PMTiles style, water points,
  /// CSR binary graph, and builds the spatial index.
  Future<void> ensureInitialized({
    void Function(String message)? onProgress,
  });

  /// Finds the optimal nearest water point and calculates the pedestrian
  /// route using adaptive geodesic early-stopping search.
  AdaptiveSearchResult? searchNearest({
    required double originLat,
    required double originLon,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  });

  /// Computes a pedestrian route to a specific destination point.
  RouteResult? routeToPoint({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  });

  /// Snaps a coordinate to the nearest walkable street segment.
  SnapResult snapToSegment(
    double lat,
    double lon, {
    double thresholdMeters = 50.0,
  });
}
