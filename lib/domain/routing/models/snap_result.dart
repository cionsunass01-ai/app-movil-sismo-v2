enum SnapStatus { success, snapNotFound }

class SnapResult {
  final SnapStatus status;
  final double originalLat;
  final double originalLon;
  final double snappedLat;
  final double snappedLon;
  final double distanceMeters;
  final int edgeId;
  final int uNodeIndex;
  final int vNodeIndex;
  final double projectionT; // 0.0 to 1.0 along segment AB
  final double segmentLengthMeters; // length of segment AB
  final double thresholdMeters;

  const SnapResult({
    required this.status,
    required this.originalLat,
    required this.originalLon,
    required this.snappedLat,
    required this.snappedLon,
    required this.distanceMeters,
    required this.edgeId,
    required this.uNodeIndex,
    required this.vNodeIndex,
    required this.projectionT,
    this.segmentLengthMeters = 0.0,
    required this.thresholdMeters,
  });

  factory SnapResult.notFound({
    required double lat,
    required double lon,
    required double thresholdMeters,
  }) {
    return SnapResult(
      status: SnapStatus.snapNotFound,
      originalLat: lat,
      originalLon: lon,
      snappedLat: lat,
      snappedLon: lon,
      distanceMeters: double.infinity,
      edgeId: -1,
      uNodeIndex: -1,
      vNodeIndex: -1,
      projectionT: 0.0,
      segmentLengthMeters: 0.0,
      thresholdMeters: thresholdMeters,
    );
  }

  bool get isSuccess => status == SnapStatus.success;

  /// Partial traversal distance along segment AB from snapped position X to node A (u)
  double get distanceToU => projectionT * segmentLengthMeters;

  /// Partial traversal distance along segment AB from snapped position X to node B (v)
  double get distanceToV => (1.0 - projectionT) * segmentLengthMeters;

  @override
  String toString() {
    if (!isSuccess) {
      return 'SNAP_NOT_FOUND (distancia a vía más cercana > ${thresholdMeters.toStringAsFixed(0)} m)';
    }
    return 'Snap a arista #$edgeId (dist: ${distanceMeters.toStringAsFixed(1)} m, t: ${projectionT.toStringAsFixed(2)})';
  }
}
