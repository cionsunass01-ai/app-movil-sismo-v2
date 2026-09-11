/// Geographical coordinates representing a point on Earth (WGS-84).
class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoLocation($latitude, $longitude)';
}

/// Status of validation for a water point's physical pedestrian access point.
enum AccessValidationStatus {
  /// The point's pedestrian access has not been formally verified on-site by SUNASS/SEDAPAL.
  /// Used for points where infrastructure location is used directly or where access discrepancies exist.
  pendingInstitutionalValidation,

  /// The pedestrian access point (gate, sidewalk, tap station) has been explicitly verified on-site.
  verified,

  /// The proposed pedestrian access point was inspected and found invalid (e.g. wall, steep cliff, highway).
  rejected,

  /// Not applicable (e.g. point is already directly on an accessible public pedestrian sidewalk).
  notApplicable;

  String get displayName {
    switch (this) {
      case AccessValidationStatus.pendingInstitutionalValidation:
        return 'Pendiente de Validación Institucional';
      case AccessValidationStatus.verified:
        return 'Acceso Peatonal Verificado';
      case AccessValidationStatus.rejected:
        return 'Acceso Rechazado / Inaccesible';
      case AccessValidationStatus.notApplicable:
        return 'No Aplica (Sobre Vía Pública)';
    }
  }

  static AccessValidationStatus fromString(String? value) {
    if (value == null) {
      return AccessValidationStatus.pendingInstitutionalValidation;
    }
    switch (value.trim().toUpperCase()) {
      case 'PENDING_INSTITUTIONAL_VALIDATION':
      case 'PENDIENTE':
        return AccessValidationStatus.pendingInstitutionalValidation;
      case 'VERIFIED':
      case 'VERIFICADO':
        return AccessValidationStatus.verified;
      case 'REJECTED':
      case 'RECHAZADO':
        return AccessValidationStatus.rejected;
      case 'NOT_APPLICABLE':
      case 'NO_APLICA':
        return AccessValidationStatus.notApplicable;
      default:
        return AccessValidationStatus.pendingInstitutionalValidation;
    }
  }
}

/// Models the physical access characteristics of a water point.
///
/// CRITICAL ARCHITECTURAL DISTINCTION:
/// [infrastructureLocation] represents the exact coordinates of the physical hydraulic asset
/// (e.g. deep well pump, reservoir tank, industrial manifold, plant valve).
///
/// [pedestrianAccessLocation] represents the exact pedestrian entry point where citizens
/// can physically line up and receive water (e.g. public gate, sidewalk dispenser).
///
/// Under zero circumstances should an algorithm invent a [pedestrianAccessLocation] coordinate
/// without empirical or institutional verification. If null, [infrastructureLocation] is preserved.
class WaterPointAccess {
  final String waterPointId;
  final GeoLocation infrastructureLocation;
  final GeoLocation? pedestrianAccessLocation;
  final AccessValidationStatus accessValidationStatus;
  final String? source;
  final DateTime? verifiedAt;
  final double? distanceToPedestrianNetworkMeters;
  final String? notes;

  const WaterPointAccess({
    required this.waterPointId,
    required this.infrastructureLocation,
    this.pedestrianAccessLocation,
    this.accessValidationStatus =
        AccessValidationStatus.pendingInstitutionalValidation,
    this.source,
    this.verifiedAt,
    this.distanceToPedestrianNetworkMeters,
    this.notes,
  });

  /// Coordinate used strictly for visual rendering on map layers.
  GeoLocation get displayLocation => infrastructureLocation;

  /// Verified physical pedestrian access location.
  /// Returns null if unverified (UNVERIFIED_ACCESS_LOCATION).
  GeoLocation? get routingAccessLocation => pedestrianAccessLocation;

  /// True ONLY if an on-site verified pedestrian access point exists.
  bool get isPedestrianAccessVerified => pedestrianAccessLocation != null;

  /// Provisional target strictly for POC technical routing.
  /// Labeled explicitly: PROVISIONAL_TECHNICAL_ROUTING_TARGET.
  GeoLocation get provisionalTechnicalRoutingTarget =>
      pedestrianAccessLocation ?? infrastructureLocation;

  /// Backwards-compatible alias for existing POC callers.
  GeoLocation get effectiveRoutingLocation => provisionalTechnicalRoutingTarget;

  /// Whether this water point has a differentiated pedestrian access point.
  bool get hasDedicatedPedestrianAccess => pedestrianAccessLocation != null;

  WaterPointAccess copyWith({
    String? waterPointId,
    GeoLocation? infrastructureLocation,
    GeoLocation? pedestrianAccessLocation,
    AccessValidationStatus? accessValidationStatus,
    String? source,
    DateTime? verifiedAt,
    double? distanceToPedestrianNetworkMeters,
    String? notes,
  }) {
    return WaterPointAccess(
      waterPointId: waterPointId ?? this.waterPointId,
      infrastructureLocation:
          infrastructureLocation ?? this.infrastructureLocation,
      pedestrianAccessLocation:
          pedestrianAccessLocation ?? this.pedestrianAccessLocation,
      accessValidationStatus:
          accessValidationStatus ?? this.accessValidationStatus,
      source: source ?? this.source,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      distanceToPedestrianNetworkMeters:
          distanceToPedestrianNetworkMeters ??
          this.distanceToPedestrianNetworkMeters,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'waterPointId': waterPointId,
    'infrastructureLocation': infrastructureLocation.toJson(),
    if (pedestrianAccessLocation != null)
      'pedestrianAccessLocation': pedestrianAccessLocation!.toJson(),
    'accessValidationStatus': accessValidationStatus.name,
    if (source != null) 'source': source,
    if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    if (distanceToPedestrianNetworkMeters != null)
      'distanceToPedestrianNetworkMeters': distanceToPedestrianNetworkMeters,
    if (notes != null) 'notes': notes,
  };

  factory WaterPointAccess.fromJson(Map<String, dynamic> json) {
    return WaterPointAccess(
      waterPointId: json['waterPointId'] as String,
      infrastructureLocation: GeoLocation.fromJson(
        json['infrastructureLocation'] as Map<String, dynamic>,
      ),
      pedestrianAccessLocation: json['pedestrianAccessLocation'] != null
          ? GeoLocation.fromJson(
              json['pedestrianAccessLocation'] as Map<String, dynamic>,
            )
          : null,
      accessValidationStatus: AccessValidationStatus.fromString(
        json['accessValidationStatus'] as String?,
      ),
      source: json['source'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      distanceToPedestrianNetworkMeters:
          (json['distanceToPedestrianNetworkMeters'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
