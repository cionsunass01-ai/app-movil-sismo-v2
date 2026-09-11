import 'operational_status.dart';
import 'water_availability.dart';
import 'queue_level.dart';
import 'access_status.dart';
import '../source/source_type.dart';
import '../source/confidence_level.dart';
import '../source/freshness.dart';
import '../source/freshness_policy.dart';

/// Represents a time-bounded dynamic operational observation of a [WaterPoint].
///
/// CRITICAL ARCHITECTURAL PRINCIPLE:
/// [WaterPointStatus] models the volatile, temporal state during emergencies.
/// It is decoupled from the immutable physical [WaterPoint] infrastructure identity.
/// An infrastructure asset can exist for decades; its status changes hourly.
///
/// Explicit UNKNOWN semantics are fully supported: when no live observation exists,
/// all fields default to unknown rather than inventing optimistic defaults.
class WaterPointStatus {
  /// Unique identifier of the associated [WaterPoint].
  final String waterPointId;

  /// Technical operational status of the facility.
  final OperationalStatus operationalStatus;

  /// Observed availability of potable water at the point.
  final WaterAvailability waterAvailability;

  /// Observed or reported queue saturation level.
  final QueueLevel queueLevel;

  /// Estimated wait time in minutes, if measured or formally reported.
  /// Strictly nullable: never synthesized from an ordinal [queueLevel].
  final int? estimatedWaitMinutes;

  /// Physical and operational status of access routes/gates to the facility.
  final AccessStatus accessStatus;

  /// Exact timestamp when this observation was recorded or confirmed.
  final DateTime updatedAt;

  /// Optional validity expiration timestamp for time-limited announcements or shifts.
  /// Strictly nullable.
  final DateTime? validUntil;

  /// Provenance source category for this operational report.
  final SourceType sourceType;

  /// Optional identifier of the reporting source (e.g. operator ID, bulletin ID, report ID).
  final String? sourceId;

  /// Evaluated or assigned confidence level for this observation.
  final ConfidenceLevel confidenceLevel;

  /// Qualitative observations or operational instructions.
  final String? notes;

  const WaterPointStatus({
    required this.waterPointId,
    this.operationalStatus = OperationalStatus.unknown,
    this.waterAvailability = WaterAvailability.unknown,
    this.queueLevel = QueueLevel.unknown,
    this.estimatedWaitMinutes,
    this.accessStatus = AccessStatus.unknown,
    required this.updatedAt,
    this.validUntil,
    required this.sourceType,
    this.sourceId,
    this.confidenceLevel = ConfidenceLevel.unknown,
    this.notes,
  });

  /// Factory creating an explicit UNKNOWN status for a point with no live data.
  factory WaterPointStatus.unknown({
    required String waterPointId,
    required DateTime updatedAt,
    SourceType sourceType = SourceType.systemInference,
    String? notes,
  }) {
    return WaterPointStatus(
      waterPointId: waterPointId,
      operationalStatus: OperationalStatus.unknown,
      waterAvailability: WaterAvailability.unknown,
      queueLevel: QueueLevel.unknown,
      estimatedWaitMinutes: null,
      accessStatus: AccessStatus.unknown,
      updatedAt: updatedAt,
      validUntil: null,
      sourceType: sourceType,
      sourceId: null,
      confidenceLevel: ConfidenceLevel.unknown,
      notes: notes ?? 'Sin información operacional confirmada',
    );
  }

  /// Evaluates the freshness state of this observation relative to a reference time.
  FreshnessState evaluateFreshness(
    DateTime referenceTime, [
    FreshnessPolicy? policy,
  ]) {
    final activePolicy = policy ?? FreshnessPolicy.standard();
    return activePolicy.evaluate(
      updatedAt: updatedAt,
      validUntil: validUntil,
      referenceTime: referenceTime,
    );
  }

  /// Whether this observation was generated from a local simulation/demo.
  bool get isSimulation => sourceType == SourceType.localSimulation;

  /// Whether this observation is considered potentially actionable for citizen dispensing.
  bool get isPotentiallyOpen =>
      operationalStatus == OperationalStatus.operational ||
      operationalStatus == OperationalStatus.limited;

  WaterPointStatus copyWith({
    String? waterPointId,
    OperationalStatus? operationalStatus,
    WaterAvailability? waterAvailability,
    QueueLevel? queueLevel,
    int? estimatedWaitMinutes,
    AccessStatus? accessStatus,
    DateTime? updatedAt,
    DateTime? validUntil,
    SourceType? sourceType,
    String? sourceId,
    ConfidenceLevel? confidenceLevel,
    String? notes,
  }) {
    return WaterPointStatus(
      waterPointId: waterPointId ?? this.waterPointId,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      waterAvailability: waterAvailability ?? this.waterAvailability,
      queueLevel: queueLevel ?? this.queueLevel,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      accessStatus: accessStatus ?? this.accessStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      validUntil: validUntil ?? this.validUntil,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'waterPointId': waterPointId,
    'operationalStatus': operationalStatus.name,
    'waterAvailability': waterAvailability.name,
    'queueLevel': queueLevel.name,
    if (estimatedWaitMinutes != null)
      'estimatedWaitMinutes': estimatedWaitMinutes,
    'accessStatus': accessStatus.name,
    'updatedAt': updatedAt.toIso8601String(),
    if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
    'sourceType': sourceType.name,
    if (sourceId != null) 'sourceId': sourceId,
    'confidenceLevel': confidenceLevel.name,
    if (notes != null) 'notes': notes,
  };

  factory WaterPointStatus.fromJson(Map<String, dynamic> json) {
    return WaterPointStatus(
      waterPointId: json['waterPointId'] as String,
      operationalStatus: OperationalStatus.fromString(
        json['operationalStatus'] as String?,
      ),
      waterAvailability: WaterAvailability.fromString(
        json['waterAvailability'] as String?,
      ),
      queueLevel: QueueLevel.fromString(json['queueLevel'] as String?),
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      accessStatus: AccessStatus.fromString(json['accessStatus'] as String?),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      sourceType: SourceType.fromString(json['sourceType'] as String?),
      sourceId: json['sourceId'] as String?,
      confidenceLevel: ConfidenceLevel.fromString(
        json['confidenceLevel'] as String?,
      ),
      notes: json['notes'] as String?,
    );
  }
}
