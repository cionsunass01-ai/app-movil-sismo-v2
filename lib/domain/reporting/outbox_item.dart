/// Status of an item awaiting asynchronous offline Store & Forward transmission.
enum OutboxStatus {
  pending,
  inFlight,
  completed,
  failed,
  deadLetter;

  String get displayName {
    switch (this) {
      case OutboxStatus.pending:
        return 'Pendiente';
      case OutboxStatus.inFlight:
        return 'En Transmisión';
      case OutboxStatus.completed:
        return 'Completado';
      case OutboxStatus.failed:
        return 'Reintentable';
      case OutboxStatus.deadLetter:
        return 'Descartado / Dead Letter';
    }
  }

  static OutboxStatus fromString(String? value) {
    if (value == null) return OutboxStatus.pending;
    switch (value.trim().toUpperCase()) {
      case 'IN_FLIGHT':
      case 'INFLIGHT':
        return OutboxStatus.inFlight;
      case 'COMPLETED':
      case 'SYNCED':
        return OutboxStatus.completed;
      case 'FAILED':
        return OutboxStatus.failed;
      case 'DEAD_LETTER':
      case 'DEADLETTER':
        return OutboxStatus.deadLetter;
      case 'PENDING':
      default:
        return OutboxStatus.pending;
    }
  }
}

/// Category of entity stored in the offline transmission queue.
enum OutboxEntityType {
  citizenReport,
  incidentReport,
  operationalObservation,
  telemetryPing;

  static OutboxEntityType fromString(String? value) {
    if (value == null) return OutboxEntityType.citizenReport;
    switch (value.trim().toUpperCase()) {
      case 'INCIDENT_REPORT':
        return OutboxEntityType.incidentReport;
      case 'OPERATIONAL_OBSERVATION':
        return OutboxEntityType.operationalObservation;
      case 'TELEMETRY_PING':
        return OutboxEntityType.telemetryPing;
      case 'CITIZEN_REPORT':
      default:
        return OutboxEntityType.citizenReport;
    }
  }
}

/// Durable Store & Forward offline transmission queue item.
///
/// Ensures zero data loss when mobile connectivity is absent.
/// SharedPreferences MUST NEVER be used for this queue; it belongs in SQLite/Drift.
class OutboxItem {
  /// Unique local identifier for this queue record (e.g. UUID).
  final String outboxId;

  /// Type of entity queued for transmission.
  final OutboxEntityType entityType;

  /// Unique idempotent ID of the underlying payload entity.
  final String entityId;

  /// Serialized payload ready for HTTP POST transmission.
  final Map<String, dynamic> payload;

  /// Timestamp when the item was enqueued.
  final DateTime createdAt;

  /// Number of transmission attempts performed so far.
  final int retryCount;

  /// Timestamp of the last transmission attempt.
  final DateTime? lastAttemptAt;

  /// Current queue state.
  final OutboxStatus status;

  /// Diagnostic error message from the last failed attempt.
  final String? lastError;

  const OutboxItem({
    required this.outboxId,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.status = OutboxStatus.pending,
    this.lastError,
  });

  /// Whether this item is eligible for another transmission attempt.
  bool canRetry({int maxRetries = 5}) {
    if (status == OutboxStatus.completed || status == OutboxStatus.deadLetter) {
      return false;
    }
    return retryCount < maxRetries;
  }

  /// Produces an updated item following a failed transmission attempt.
  OutboxItem recordFailure({
    required String error,
    required DateTime attemptTime,
    int maxRetries = 5,
  }) {
    final newCount = retryCount + 1;
    final newStatus = newCount >= maxRetries
        ? OutboxStatus.deadLetter
        : OutboxStatus.failed;
    return copyWith(
      retryCount: newCount,
      lastAttemptAt: attemptTime,
      status: newStatus,
      lastError: error,
    );
  }

  OutboxItem copyWith({
    String? outboxId,
    OutboxEntityType? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    OutboxStatus? status,
    String? lastError,
  }) {
    return OutboxItem(
      outboxId: outboxId ?? this.outboxId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
    'outboxId': outboxId,
    'entityType': entityType.name,
    'entityId': entityId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    if (lastAttemptAt != null)
      'lastAttemptAt': lastAttemptAt!.toIso8601String(),
    'status': status.name,
    if (lastError != null) 'lastError': lastError,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    return OutboxItem(
      outboxId: json['outboxId'] as String,
      entityType: OutboxEntityType.fromString(json['entityType'] as String?),
      entityId: json['entityId'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as int?) ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      status: OutboxStatus.fromString(json['status'] as String?),
      lastError: json['lastError'] as String?,
    );
  }
}
