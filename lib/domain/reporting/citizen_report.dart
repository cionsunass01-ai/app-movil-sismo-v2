import '../water/water_point_access.dart';

/// Categories of citizen field reports regarding water points or local access.
enum CitizenReportType {
  pointClosed,
  noWater,
  longQueue,
  accessBlocked,
  pointAvailable,
  other;

  String get displayName {
    switch (this) {
      case CitizenReportType.pointClosed:
        return 'Punto Cerrado / Sin Atención';
      case CitizenReportType.noWater:
        return 'Sin Agua / Caudal Agotado';
      case CitizenReportType.longQueue:
        return 'Cola Muy Larga / Saturada';
      case CitizenReportType.accessBlocked:
        return 'Acceso o Vía Bloqueada';
      case CitizenReportType.pointAvailable:
        return 'Punto Abasteciendo Normalmente';
      case CitizenReportType.other:
        return 'Otro Reporte Ciudadano';
    }
  }

  static CitizenReportType fromString(String? value) {
    if (value == null) return CitizenReportType.other;
    switch (value.trim().toUpperCase()) {
      case 'POINT_CLOSED':
      case 'PUNTO_CERRADO':
        return CitizenReportType.pointClosed;
      case 'NO_WATER':
      case 'SIN_AGUA':
        return CitizenReportType.noWater;
      case 'LONG_QUEUE':
      case 'COLA_LARGA':
        return CitizenReportType.longQueue;
      case 'ACCESS_BLOCKED':
      case 'ACCESO_BLOQUEADO':
        return CitizenReportType.accessBlocked;
      case 'POINT_AVAILABLE':
      case 'PUNTO_DISPONIBLE':
        return CitizenReportType.pointAvailable;
      case 'OTHER':
      default:
        return CitizenReportType.other;
    }
  }
}

/// Synchronization lifecycle status for local citizen reports awaiting remote transmission.
enum ReportSyncStatus {
  pending,
  syncing,
  synced,
  failed,
  rejected;

  String get displayName {
    switch (this) {
      case ReportSyncStatus.pending:
        return 'Pendiente de Sincronización';
      case ReportSyncStatus.syncing:
        return 'Enviando...';
      case ReportSyncStatus.synced:
        return 'Sincronizado';
      case ReportSyncStatus.failed:
        return 'Error de Transmisión';
      case ReportSyncStatus.rejected:
        return 'Rechazado por Servidor';
    }
  }

  static ReportSyncStatus fromString(String? value) {
    if (value == null) return ReportSyncStatus.pending;
    switch (value.trim().toUpperCase()) {
      case 'SYNCING':
        return ReportSyncStatus.syncing;
      case 'SYNCED':
        return ReportSyncStatus.synced;
      case 'FAILED':
        return ReportSyncStatus.failed;
      case 'REJECTED':
        return ReportSyncStatus.rejected;
      case 'PENDING':
      default:
        return ReportSyncStatus.pending;
    }
  }
}

/// A crowdsourced citizen report capturing observations in the field.
///
/// CRITICAL ARCHITECTURAL PRINCIPLE:
/// An individual [CitizenReport] NEVER directly overwrites or mutates official
/// [WaterPointStatus]. It is stored as an independent observation event for
/// corroboration, aggregation, or operator triage.
class CitizenReport {
  /// Unique canonical report identifier.
  final String reportId;

  /// Idempotent client-generated token ensuring safe retries without duplication.
  final String deviceGeneratedId;

  /// Target water point ID, if this report is specific to a facility.
  final String? waterPointId;

  /// Associated incident ID, if this report references an obstruction or disaster.
  final String? incidentId;

  /// Classification of the report.
  final CitizenReportType reportType;

  /// Creation timestamp on the user device.
  final DateTime createdAt;

  /// Approximate user coordinate at report submission time.
  /// PRIVACY NOTE: Position is only captured upon explicit user action and
  /// can be truncated / fuzzy-hashed to protect citizen privacy.
  final GeoLocation? capturedLocation;

  /// Arbitrary supplementary key-value payload.
  final Map<String, dynamic> payload;

  /// Store & Forward synchronization status.
  final ReportSyncStatus syncStatus;

  /// Number of other reports corroborating this observation (if calculated).
  final int corroborationCount;

  /// User comments or free text.
  final String? notes;

  const CitizenReport({
    required this.reportId,
    required this.deviceGeneratedId,
    this.waterPointId,
    this.incidentId,
    required this.reportType,
    required this.createdAt,
    this.capturedLocation,
    this.payload = const {},
    this.syncStatus = ReportSyncStatus.pending,
    this.corroborationCount = 0,
    this.notes,
  });

  CitizenReport copyWith({
    String? reportId,
    String? deviceGeneratedId,
    String? waterPointId,
    String? incidentId,
    CitizenReportType? reportType,
    DateTime? createdAt,
    GeoLocation? capturedLocation,
    Map<String, dynamic>? payload,
    ReportSyncStatus? syncStatus,
    int? corroborationCount,
    String? notes,
  }) {
    return CitizenReport(
      reportId: reportId ?? this.reportId,
      deviceGeneratedId: deviceGeneratedId ?? this.deviceGeneratedId,
      waterPointId: waterPointId ?? this.waterPointId,
      incidentId: incidentId ?? this.incidentId,
      reportType: reportType ?? this.reportType,
      createdAt: createdAt ?? this.createdAt,
      capturedLocation: capturedLocation ?? this.capturedLocation,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      corroborationCount: corroborationCount ?? this.corroborationCount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'deviceGeneratedId': deviceGeneratedId,
    if (waterPointId != null) 'waterPointId': waterPointId,
    if (incidentId != null) 'incidentId': incidentId,
    'reportType': reportType.name,
    'createdAt': createdAt.toIso8601String(),
    if (capturedLocation != null)
      'capturedLocation': capturedLocation!.toJson(),
    'payload': payload,
    'syncStatus': syncStatus.name,
    'corroborationCount': corroborationCount,
    if (notes != null) 'notes': notes,
  };

  factory CitizenReport.fromJson(Map<String, dynamic> json) {
    return CitizenReport(
      reportId: json['reportId'] as String,
      deviceGeneratedId: json['deviceGeneratedId'] as String,
      waterPointId: json['waterPointId'] as String?,
      incidentId: json['incidentId'] as String?,
      reportType: CitizenReportType.fromString(json['reportType'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      capturedLocation: json['capturedLocation'] != null
          ? GeoLocation.fromJson(
              json['capturedLocation'] as Map<String, dynamic>,
            )
          : null,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      syncStatus: ReportSyncStatus.fromString(json['syncStatus'] as String?),
      corroborationCount: (json['corroborationCount'] as int?) ?? 0,
      notes: json['notes'] as String?,
    );
  }
}
