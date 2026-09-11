import 'water_point_access.dart';

/// Classification of water distribution sources in emergency scenarios.
enum WaterSourceKind {
  /// Permanent fixed physical asset (e.g. well, reservoir, camera manifold).
  fixedInfrastructure,

  /// Temporary stationary distribution station (e.g. bladder tank, emergency tap).
  temporaryStation,

  /// Mobile distribution unit (e.g. tanker truck / camión cisterna).
  tankerTruck;

  String get displayName {
    switch (this) {
      case WaterSourceKind.fixedInfrastructure:
        return 'Punto Fijo (Infraestructura)';
      case WaterSourceKind.temporaryStation:
        return 'Punto de Distribución Temporal';
      case WaterSourceKind.tankerTruck:
        return 'Camión Cisterna Móvil';
    }
  }
}

/// Abstract contract for any physical or mobile water dispensing entity in AguaCION.
///
/// DESIGN RATIONALE (ADR-004):
/// We avoid deep inheritance hierarchies. [WaterPoint] implements [WaterSource]
/// for fixed infrastructure. Future mobile tanker trucks or temporary bladders
/// can implement [WaterSource] without breaking the offline pedestrian routing pipeline.
abstract class WaterSource {
  /// Canonical identifier for the dispensing source.
  String get id;

  /// Human-readable label or official designation.
  String get displayName;

  /// Classification kind of this water source.
  WaterSourceKind get sourceKind;

  /// Current target location for routing or citizen orientation.
  GeoLocation get location;

  /// Whether this source is stationary (fixed) or mobile (tanker).
  bool get isStationary;
}

/// Architectural compatibility descriptor for future mobile tanker trucks.
///
/// NOTE: Camiones cisterna are NOT implemented in MVP/Hito 3A because
/// official institutional GPS feeds and operating schedules do not yet exist.
/// This model defines the future schema contract required by SUNASS/SEDAPAL.
class TankerTruckProfile {
  final String vehicleId;
  final String? licensePlate;
  final GeoLocation currentLocation;
  final String? totalCapacityRaw;
  final String? remainingCapacityRaw;
  final String? currentStopName;
  final String? nextStopName;
  final DateTime? estimatedNextStopArrival;
  final DateTime locationUpdatedAt;
  final DateTime? validUntil;

  const TankerTruckProfile({
    required this.vehicleId,
    this.licensePlate,
    required this.currentLocation,
    this.totalCapacityRaw,
    this.remainingCapacityRaw,
    this.currentStopName,
    this.nextStopName,
    this.estimatedNextStopArrival,
    required this.locationUpdatedAt,
    this.validUntil,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    if (licensePlate != null) 'licensePlate': licensePlate,
    'currentLocation': currentLocation.toJson(),
    if (totalCapacityRaw != null) 'totalCapacityRaw': totalCapacityRaw,
    if (remainingCapacityRaw != null)
      'remainingCapacityRaw': remainingCapacityRaw,
    if (currentStopName != null) 'currentStopName': currentStopName,
    if (nextStopName != null) 'nextStopName': nextStopName,
    if (estimatedNextStopArrival != null)
      'estimatedNextStopArrival': estimatedNextStopArrival!.toIso8601String(),
    'locationUpdatedAt': locationUpdatedAt.toIso8601String(),
    if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
  };
}
