enum RouteStatus {
  success,
  unreachable,
  originSnapFailed,
  destinationSnapFailed,
}

class RouteResult {
  final RouteStatus status;
  final double distanceMeters;
  final double durationMinutes; // walking speed ~4 km/h = 67 m/min
  final double calculationTimeMs;
  final int visitedNodes;
  final List<List<double>>
  polylineCoords; // [[lon, lat], ...] for GeoJSON LineString
  final List<int> pathNodeIndices;
  final List<int> pathEdgeIds;
  final double originSnapDistance;
  final double destinationSnapDistance;
  final int blockedEdgesCount;
  final String? errorMessage;

  const RouteResult({
    required this.status,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.calculationTimeMs,
    required this.visitedNodes,
    required this.polylineCoords,
    required this.pathNodeIndices,
    required this.pathEdgeIds,
    required this.originSnapDistance,
    required this.destinationSnapDistance,
    this.blockedEdgesCount = 0,
    this.errorMessage,
  });

  factory RouteResult.failed({
    required RouteStatus status,
    required String message,
    double calculationTimeMs = 0.0,
    int visitedNodes = 0,
  }) {
    return RouteResult(
      status: status,
      distanceMeters: double.infinity,
      durationMinutes: double.infinity,
      calculationTimeMs: calculationTimeMs,
      visitedNodes: visitedNodes,
      polylineCoords: const [],
      pathNodeIndices: const [],
      pathEdgeIds: const [],
      originSnapDistance: 0.0,
      destinationSnapDistance: 0.0,
      errorMessage: message,
    );
  }

  bool get isSuccess => status == RouteStatus.success;

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final mins = durationMinutes.round();
    if (mins < 60) return '$mins min a pie';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return '${hrs}h ${rem}m a pie';
  }

  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': polylineCoords},
      'properties': {
        'distance_m': distanceMeters,
        'duration_min': durationMinutes,
        'calc_ms': calculationTimeMs,
        'visited_nodes': visitedNodes,
      },
    };
  }
}
