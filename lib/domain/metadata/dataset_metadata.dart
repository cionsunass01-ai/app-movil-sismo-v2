/// Status of offline dataset version synchronization.
enum DatasetDownloadStatus {
  upToDate,
  updateAvailable,
  downloading,
  verifying,
  readyToApply,
  failed;

  String get displayName {
    switch (this) {
      case DatasetDownloadStatus.upToDate:
        return 'Actualizado';
      case DatasetDownloadStatus.updateAvailable:
        return 'Actualización Disponible';
      case DatasetDownloadStatus.downloading:
        return 'Descargando Paquete Offline...';
      case DatasetDownloadStatus.verifying:
        return 'Verificando Integridad (SHA-256)...';
      case DatasetDownloadStatus.readyToApply:
        return 'Listo para Instalar';
      case DatasetDownloadStatus.failed:
        return 'Error de Descarga (Manteniendo Versión Anterior)';
    }
  }
}

/// Metadata describing an installed offline dataset (e.g. 433 points, PMTiles, or CSR graph).
class DatasetMetadata {
  /// Unique identifier of the dataset (e.g. `water_points_lima_callao`).
  final String datasetId;

  /// Semantic or date-based version identifier (e.g. `2026.08.19-v1.0`).
  final String version;

  /// Timestamp when the dataset package was compiled or exported.
  final DateTime generatedAt;

  /// Official publication date of the source authority records.
  final DateTime sourceDate;

  /// Timestamp when this package was installed/extracted on the mobile device.
  final DateTime installedAt;

  /// SHA-256 cryptographic digest ensuring file integrity.
  final String? checksum;

  /// Total number of verified records contained in the dataset.
  final int recordCount;

  /// Format or schema revision number for backwards compatibility.
  final int schemaVersion;

  const DatasetMetadata({
    required this.datasetId,
    required this.version,
    required this.generatedAt,
    required this.sourceDate,
    required this.installedAt,
    this.checksum,
    this.recordCount = 0,
    this.schemaVersion = 1,
  });

  /// True if the installed dataset is older than a specified duration threshold.
  bool isStale(DateTime referenceTime, Duration threshold) {
    return referenceTime.difference(sourceDate) > threshold;
  }

  DatasetMetadata copyWith({
    String? datasetId,
    String? version,
    DateTime? generatedAt,
    DateTime? sourceDate,
    DateTime? installedAt,
    String? checksum,
    int? recordCount,
    int? schemaVersion,
  }) {
    return DatasetMetadata(
      datasetId: datasetId ?? this.datasetId,
      version: version ?? this.version,
      generatedAt: generatedAt ?? this.generatedAt,
      sourceDate: sourceDate ?? this.sourceDate,
      installedAt: installedAt ?? this.installedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
    'datasetId': datasetId,
    'version': version,
    'generatedAt': generatedAt.toIso8601String(),
    'sourceDate': sourceDate.toIso8601String(),
    'installedAt': installedAt.toIso8601String(),
    if (checksum != null) 'checksum': checksum,
    'recordCount': recordCount,
    'schemaVersion': schemaVersion,
  };

  factory DatasetMetadata.fromJson(Map<String, dynamic> json) {
    return DatasetMetadata(
      datasetId: json['datasetId'] as String,
      version: json['version'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      sourceDate: DateTime.parse(json['sourceDate'] as String),
      installedAt: DateTime.parse(json['installedAt'] as String),
      checksum: json['checksum'] as String?,
      recordCount: (json['recordCount'] as int?) ?? 0,
      schemaVersion: (json['schemaVersion'] as int?) ?? 1,
    );
  }
}

/// Tracking state for dataset versioning and atomic update management.
///
/// Ensures that if a new delta or bundle download fails, the existing
/// verified offline dataset remains 100% active and unharmed.
class DatasetVersionControl {
  final DatasetMetadata currentInstalled;
  final DatasetMetadata? pendingUpdate;
  final DatasetDownloadStatus downloadStatus;
  final String? lastError;

  const DatasetVersionControl({
    required this.currentInstalled,
    this.pendingUpdate,
    this.downloadStatus = DatasetDownloadStatus.upToDate,
    this.lastError,
  });

  bool get hasActiveUpdate => pendingUpdate != null;

  Map<String, dynamic> toJson() => {
    'currentInstalled': currentInstalled.toJson(),
    if (pendingUpdate != null) 'pendingUpdate': pendingUpdate!.toJson(),
    'downloadStatus': downloadStatus.name,
    if (lastError != null) 'lastError': lastError,
  };
}
