/// Qualitative ordinal scale representing crowd congestion and queue density at a water point.
///
/// NOTE: Separated entirely from exact person counts or invented wait times.
/// Exact wait times (in minutes) are modeled as a separate, nullable field in [WaterPointStatus].
enum QueueLevel {
  /// No reports or observations regarding queue length have been recorded.
  unknown,

  /// Minimal or no line (immediate or near-immediate service, typically < 10 people).
  low,

  /// Moderate queue with steady movement (typically 10 - 40 people).
  medium,

  /// Long queue with noticeable waiting (typically > 40 people, extending down the block).
  high,

  /// Severe congestion or overcrowding; queue has reached physical or security capacity limits.
  saturated;

  String get displayName {
    switch (this) {
      case QueueLevel.unknown:
        return 'Cola No Reportada';
      case QueueLevel.low:
        return 'Cola Baja / Fluida';
      case QueueLevel.medium:
        return 'Cola Moderada';
      case QueueLevel.high:
        return 'Cola Larga';
      case QueueLevel.saturated:
        return 'Punto Saturado / Alta Congestión';
    }
  }

  static QueueLevel fromString(String? value) {
    if (value == null) return QueueLevel.unknown;
    switch (value.trim().toUpperCase()) {
      case 'LOW':
      case 'BAJA':
        return QueueLevel.low;
      case 'MEDIUM':
      case 'MODERADA':
      case 'MEDIA':
        return QueueLevel.medium;
      case 'HIGH':
      case 'ALTA':
      case 'LARGA':
        return QueueLevel.high;
      case 'SATURATED':
      case 'SATURADO':
        return QueueLevel.saturated;
      case 'UNKNOWN':
      case 'DESCONOCIDO':
      default:
        return QueueLevel.unknown;
    }
  }
}
