import '../source/source_type.dart';

/// Categories of auditable operational events in AguaCION.
enum OperationalEventType {
  statusChanged,
  waterAvailabilityChanged,
  queueSaturationUpdated,
  incidentReported,
  incidentResolved,
  sourceConflictDetected,
  manualSupervisorOverride,
  datasetVersionInstalled;

  String get displayName {
    switch (this) {
      case OperationalEventType.statusChanged:
        return 'Cambio de Estado Operativo';
      case OperationalEventType.waterAvailabilityChanged:
        return 'Cambio de Disponibilidad de Agua';
      case OperationalEventType.queueSaturationUpdated:
        return 'Actualización de Saturación / Cola';
      case OperationalEventType.incidentReported:
        return 'Registro de Incidente';
      case OperationalEventType.incidentResolved:
        return 'Incidente Resuelto';
      case OperationalEventType.sourceConflictDetected:
        return 'Conflicto entre Fuentes Detectado';
      case OperationalEventType.manualSupervisorOverride:
        return 'Anulación Manual por Supervisor';
      case OperationalEventType.datasetVersionInstalled:
        return 'Instalación de Nueva Versión de Dataset';
    }
  }

  static OperationalEventType fromString(String? value) {
    if (value == null) return OperationalEventType.statusChanged;
    switch (value.trim().toUpperCase()) {
      case 'WATER_AVAILABILITY_CHANGED':
        return OperationalEventType.waterAvailabilityChanged;
      case 'QUEUE_SATURATION_UPDATED':
        return OperationalEventType.queueSaturationUpdated;
      case 'INCIDENT_REPORTED':
        return OperationalEventType.incidentReported;
      case 'INCIDENT_RESOLVED':
        return OperationalEventType.incidentResolved;
      case 'SOURCE_CONFLICT_DETECTED':
        return OperationalEventType.sourceConflictDetected;
      case 'MANUAL_SUPERVISOR_OVERRIDE':
        return OperationalEventType.manualSupervisorOverride;
      case 'DATASET_VERSION_INSTALLED':
        return OperationalEventType.datasetVersionInstalled;
      case 'STATUS_CHANGED':
      default:
        return OperationalEventType.statusChanged;
    }
  }
}

/// An immutable, append-only audit trail event.
///
/// DESIGN RATIONALE (ADR-007):
/// Provides high-integrity institutional traceability for all operational updates
/// during disaster management without requiring blockchain complexity or distributed consensus.
class OperationalEvent {
  final String eventId;
  final String entityType;
  final String entityId;
  final OperationalEventType eventType;
  final String? previousValue;
  final String? newValue;
  final SourceType source;
  final String? sourceId;
  final DateTime occurredAt;
  final DateTime recordedAt;

  /// Optional future placeholder: DIGITAL_SIGNATURE_AUDIT_IMPLEMENTED = NO in Hito 3A.
  /// Classification: FUTURE_SECURITY_DESIGN, NOT_IMPLEMENTED, NOT_VALIDATED.
  final String? digitalSignature;

  const OperationalEvent({
    required this.eventId,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    this.previousValue,
    this.newValue,
    required this.source,
    this.sourceId,
    required this.occurredAt,
    required this.recordedAt,
    this.digitalSignature,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'entityType': entityType,
    'entityId': entityId,
    'eventType': eventType.name,
    if (previousValue != null) 'previousValue': previousValue,
    if (newValue != null) 'newValue': newValue,
    'source': source.name,
    if (sourceId != null) 'sourceId': sourceId,
    'occurredAt': occurredAt.toIso8601String(),
    'recordedAt': recordedAt.toIso8601String(),
    if (digitalSignature != null) 'digitalSignature': digitalSignature,
  };

  factory OperationalEvent.fromJson(Map<String, dynamic> json) {
    return OperationalEvent(
      eventId: json['eventId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      eventType: OperationalEventType.fromString(json['eventType'] as String?),
      previousValue: json['previousValue'] as String?,
      newValue: json['newValue'] as String?,
      source: SourceType.fromString(json['source'] as String?),
      sourceId: json['sourceId'] as String?,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      digitalSignature: json['digitalSignature'] as String?,
    );
  }
}
