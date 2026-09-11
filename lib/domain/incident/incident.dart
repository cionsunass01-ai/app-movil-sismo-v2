import '../water/water_point_access.dart';
import '../source/source_type.dart';
import '../source/confidence_level.dart';

/// Classification of physical or operational incidents affecting water points or roads.
enum IncidentType {
  roadBlock,
  bridgeDamage,
  flooding,
  landslide,
  facilityDamage,
  accessRestriction,
  other;

  String get displayName {
    switch (this) {
      case IncidentType.roadBlock:
        return 'Vía Bloqueada / Obstáculo Peatonal';
      case IncidentType.bridgeDamage:
        return 'Daño Estructural en Puente o Paso';
      case IncidentType.flooding:
        return 'Inundación / Anegamiento';
      case IncidentType.landslide:
        return 'Huayco / Deslizamiento';
      case IncidentType.facilityDamage:
        return 'Daño en Instalación de Agua';
      case IncidentType.accessRestriction:
        return 'Restricción de Acceso / Zona Cerrada';
      case IncidentType.other:
        return 'Otro Incidente';
    }
  }

  static IncidentType fromString(String? value) {
    if (value == null) return IncidentType.other;
    switch (value.trim().toUpperCase()) {
      case 'ROAD_BLOCK':
      case 'ROADBLOCK':
        return IncidentType.roadBlock;
      case 'BRIDGE_DAMAGE':
        return IncidentType.bridgeDamage;
      case 'FLOODING':
        return IncidentType.flooding;
      case 'LANDSLIDE':
      case 'HUAYCO':
        return IncidentType.landslide;
      case 'FACILITY_DAMAGE':
        return IncidentType.facilityDamage;
      case 'ACCESS_RESTRICTION':
        return IncidentType.accessRestriction;
      case 'OTHER':
      default:
        return IncidentType.other;
    }
  }
}

/// Operational severity level of an incident.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentSeverity.low:
        return 'Baja';
      case IncidentSeverity.medium:
        return 'Media';
      case IncidentSeverity.high:
        return 'Alta';
      case IncidentSeverity.critical:
        return 'Crítica (Peligro Inminente)';
    }
  }

  static IncidentSeverity fromString(String? value) {
    if (value == null) return IncidentSeverity.medium;
    switch (value.trim().toUpperCase()) {
      case 'LOW':
      case 'BAJA':
        return IncidentSeverity.low;
      case 'HIGH':
      case 'ALTA':
        return IncidentSeverity.high;
      case 'CRITICAL':
      case 'CRITICA':
      case 'CRÍTICA':
        return IncidentSeverity.critical;
      case 'MEDIUM':
      case 'MEDIA':
      default:
        return IncidentSeverity.medium;
    }
  }
}

/// Lifecycle status of an incident report.
enum IncidentStatus {
  underAssessment,
  active,
  resolved,
  expired;

  String get displayName {
    switch (this) {
      case IncidentStatus.underAssessment:
        return 'En Evaluación';
      case IncidentStatus.active:
        return 'Activo / Vigente';
      case IncidentStatus.resolved:
        return 'Resuelto / Despejado';
      case IncidentStatus.expired:
        return 'Expirado / Sin Confirmación';
    }
  }

  static IncidentStatus fromString(String? value) {
    if (value == null) return IncidentStatus.active;
    switch (value.trim().toUpperCase()) {
      case 'UNDER_ASSESSMENT':
        return IncidentStatus.underAssessment;
      case 'RESOLVED':
        return IncidentStatus.resolved;
      case 'EXPIRED':
        return IncidentStatus.expired;
      case 'ACTIVE':
      default:
        return IncidentStatus.active;
    }
  }
}

/// Represents an incident that may impact pedestrian routing edges, accessibility,
/// or the physical integrity of a water point.
class Incident {
  final String incidentId;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String? description;

  /// Approximate center coordinate of the incident, if point-based.
  final GeoLocation? location;

  /// Optional GeoJSON representation for linear or polygon incident geometries.
  final String? geometryGeoJson;

  final DateTime reportedAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  final SourceType sourceType;
  final ConfidenceLevel confidenceLevel;

  /// IDs of specific [WaterPoint] entities physically affected by this incident.
  final List<String> affectedWaterPointIds;

  /// IDs or indices of pedestrian graph edges obstructed or disabled by this incident.
  final List<int> affectedGraphEdgeIds;

  const Incident({
    required this.incidentId,
    required this.type,
    this.severity = IncidentSeverity.medium,
    this.status = IncidentStatus.active,
    this.description,
    this.location,
    this.geometryGeoJson,
    required this.reportedAt,
    this.updatedAt,
    this.expiresAt,
    required this.sourceType,
    this.confidenceLevel = ConfidenceLevel.medium,
    this.affectedWaterPointIds = const [],
    this.affectedGraphEdgeIds = const [],
  });

  /// Evaluates whether the incident is currently active and unexpired.
  bool isActive(DateTime referenceTime) {
    if (status != IncidentStatus.active) return false;
    if (expiresAt != null && referenceTime.isAfter(expiresAt!)) return false;
    return true;
  }

  Incident copyWith({
    String? incidentId,
    IncidentType? type,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? description,
    GeoLocation? location,
    String? geometryGeoJson,
    DateTime? reportedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    SourceType? sourceType,
    ConfidenceLevel? confidenceLevel,
    List<String>? affectedWaterPointIds,
    List<int>? affectedGraphEdgeIds,
  }) {
    return Incident(
      incidentId: incidentId ?? this.incidentId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      location: location ?? this.location,
      geometryGeoJson: geometryGeoJson ?? this.geometryGeoJson,
      reportedAt: reportedAt ?? this.reportedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      sourceType: sourceType ?? this.sourceType,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      affectedWaterPointIds:
          affectedWaterPointIds ?? this.affectedWaterPointIds,
      affectedGraphEdgeIds: affectedGraphEdgeIds ?? this.affectedGraphEdgeIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'incidentId': incidentId,
    'type': type.name,
    'severity': severity.name,
    'status': status.name,
    if (description != null) 'description': description,
    if (location != null) 'location': location!.toJson(),
    if (geometryGeoJson != null) 'geometryGeoJson': geometryGeoJson,
    'reportedAt': reportedAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    'sourceType': sourceType.name,
    'confidenceLevel': confidenceLevel.name,
    'affectedWaterPointIds': affectedWaterPointIds,
    'affectedGraphEdgeIds': affectedGraphEdgeIds,
  };

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      incidentId: json['incidentId'] as String,
      type: IncidentType.fromString(json['type'] as String?),
      severity: IncidentSeverity.fromString(json['severity'] as String?),
      status: IncidentStatus.fromString(json['status'] as String?),
      description: json['description'] as String?,
      location: json['location'] != null
          ? GeoLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      geometryGeoJson: json['geometryGeoJson'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      sourceType: SourceType.fromString(json['sourceType'] as String?),
      confidenceLevel: ConfidenceLevel.fromString(
        json['confidenceLevel'] as String?,
      ),
      affectedWaterPointIds:
          (json['affectedWaterPointIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      affectedGraphEdgeIds:
          (json['affectedGraphEdgeIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }
}
