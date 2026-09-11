import '../source/confidence_level.dart';
import '../source/source_type.dart';

/// Target attribute or field observed in an operational observation.
enum ObservationField {
  operationalStatus,
  waterAvailability,
  queueLevel,
  accessStatus,
  generalCondition;

  String get displayName {
    switch (this) {
      case ObservationField.operationalStatus:
        return 'Estado Operativo';
      case ObservationField.waterAvailability:
        return 'Disponibilidad de Agua';
      case ObservationField.queueLevel:
        return 'Nivel de Cola';
      case ObservationField.accessStatus:
        return 'Acceso Físico';
      case ObservationField.generalCondition:
        return 'Condición General';
    }
  }
}

/// An immutable, append-only operational observation emitted by an official source,
/// an accredited field operator, or a citizen.
///
/// DESIGN RATIONALE (ADR-003):
/// Rather than storing only a mutable "current state", recording individual
/// observations provides institutional traceability, conflict detection,
/// and allows state materialization without requiring a distributed ledger.
class WaterPointObservation {
  final String observationId;
  final String waterPointId;
  final ObservationField field;
  final String value;
  final DateTime observedAt;
  final SourceType source;
  final String? sourceId;
  final ConfidenceLevel confidence;
  final String? notes;

  const WaterPointObservation({
    required this.observationId,
    required this.waterPointId,
    required this.field,
    required this.value,
    required this.observedAt,
    required this.source,
    this.sourceId,
    required this.confidence,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'observationId': observationId,
    'waterPointId': waterPointId,
    'field': field.name,
    'value': value,
    'observedAt': observedAt.toIso8601String(),
    'source': source.name,
    if (sourceId != null) 'sourceId': sourceId,
    'confidence': confidence.name,
    if (notes != null) 'notes': notes,
  };

  factory WaterPointObservation.fromJson(Map<String, dynamic> json) {
    return WaterPointObservation(
      observationId: json['observationId'] as String,
      waterPointId: json['waterPointId'] as String,
      field: ObservationField.values.firstWhere(
        (f) => f.name == json['field'],
        orElse: () => ObservationField.generalCondition,
      ),
      value: json['value'] as String,
      observedAt: DateTime.parse(json['observedAt'] as String),
      source: SourceType.fromString(json['source'] as String?),
      sourceId: json['sourceId'] as String?,
      confidence: ConfidenceLevel.fromString(json['confidence'] as String?),
      notes: json['notes'] as String?,
    );
  }
}

/// Type of contradiction detected between operational data sources.
enum ConflictType {
  /// Official utility source claims open, but multiple field/citizen reports state closed.
  officialVsCitizen,

  /// Citizen reports within the same time window contradict each other significantly.
  citizenContradiction,

  /// An old official report conflicts with newer field operator telemetry.
  temporalDivergence,

  /// General undetermined discrepancy.
  undetermined,
}

/// Represents a detected conflict between two or more operational reports for the same point.
///
/// Example: SEDAPAL bulletin states point is OPEN, but 20 citizens report point is CLOSED.
/// The system does NOT arbitrarily overwrite or erase either source; it explicitly
/// flags the conflict for transparency in UI and logs.
class SourceConflict {
  /// Explicit status indicator representing contradictory reports.
  static const String statusConflictingInformation = 'CONFLICTING_INFORMATION';

  final String waterPointId;
  final ObservationField conflictingField;
  final ConflictType conflictType;
  final WaterPointObservation? officialObservation;
  final List<WaterPointObservation> crowdSourcedObservations;
  final DateTime detectedAt;
  final String explanation;

  /// Operational resolution decision status.
  /// Strictly PENDING_POLICY in Hito 3A: The engine does NOT unilaterally or automatically
  /// resolve conflicts until institutional rules are promulgated by SUNASS/SEDAPAL.
  final String operationalDecision;

  const SourceConflict({
    required this.waterPointId,
    required this.conflictingField,
    required this.conflictType,
    this.officialObservation,
    this.crowdSourcedObservations = const [],
    required this.detectedAt,
    required this.explanation,
    this.operationalDecision = 'PENDING_POLICY',
  });

  /// True if there is at least one active conflict condition.
  bool get isConflicting => crowdSourcedObservations.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'status': statusConflictingInformation,
    'waterPointId': waterPointId,
    'conflictingField': conflictingField.name,
    'conflictType': conflictType.name,
    if (officialObservation != null)
      'officialObservation': officialObservation!.toJson(),
    'crowdSourcedObservations': crowdSourcedObservations
        .map((o) => o.toJson())
        .toList(),
    'detectedAt': detectedAt.toIso8601String(),
    'explanation': explanation,
    'operationalDecision': operationalDecision,
  };
}
