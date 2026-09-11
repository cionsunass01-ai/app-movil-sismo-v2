/// Indicates the presence and dispensing capability of potable water at a point.
///
/// NOTE: "available" strictly means: "The most recent credible source report indicates water is flowing/dispensing".
/// It does NOT constitute a legal, physical, or permanent hydraulic guarantee by AguaCION.
/// No liters, cubic meters, or pressure values are assumed or invented.
enum WaterAvailability {
  /// No verified observation regarding water flow or tank capacity is available.
  unknown,

  /// Water is actively being dispensed or the supply line is verified pressurized.
  available,

  /// Water supply is low, flow rate is severely degraded, or reservoir level is nearing empty.
  low,

  /// The point's local storage/well is temporarily empty, awaiting scheduled tanker refill or pump restart.
  temporarilyEmpty,

  /// Water is confirmed absent or cut off (e.g. broken pipe, exhausted aquifer, contaminated source).
  unavailable;

  String get displayName {
    switch (this) {
      case WaterAvailability.unknown:
        return 'Disponibilidad No Verificada';
      case WaterAvailability.available:
        return 'Agua Disponible';
      case WaterAvailability.low:
        return 'Suministro Bajo / Caudal Mínimo';
      case WaterAvailability.temporarilyEmpty:
        return 'Temporalmente Agotado';
      case WaterAvailability.unavailable:
        return 'Sin Suministro de Agua';
    }
  }

  /// Whether water is confirmed to be present to any degree.
  bool get hasWater =>
      this == WaterAvailability.available || this == WaterAvailability.low;

  static WaterAvailability fromString(String? value) {
    if (value == null) return WaterAvailability.unknown;
    switch (value.trim().toUpperCase()) {
      case 'AVAILABLE':
      case 'DISPONIBLE':
        return WaterAvailability.available;
      case 'LOW':
      case 'BAJO':
        return WaterAvailability.low;
      case 'TEMPORARILY_EMPTY':
      case 'TEMPORALMENTE_AGOTADO':
        return WaterAvailability.temporarilyEmpty;
      case 'UNAVAILABLE':
      case 'SIN_AGUA':
      case 'NO_DISPONIBLE':
        return WaterAvailability.unavailable;
      case 'UNKNOWN':
      case 'DESCONOCIDO':
      default:
        return WaterAvailability.unknown;
    }
  }
}
