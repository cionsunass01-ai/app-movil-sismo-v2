/// Qualitative confidence level assigned to an operational observation or data state.
///
/// NOTE: Categorical and explainable. Never invent arbitrary floating point percentages
/// (e.g. "87% confidence") without empirical statistical justification.
enum ConfidenceLevel {
  /// Confidence is unassessed or undetermined.
  unknown,

  /// Single uncorroborated citizen report or distant inference.
  low,

  /// Multiple concordant citizen reports or secondary administrative report.
  medium,

  /// Direct observation by accredited field operator or cross-verified institutional broadcast.
  high,

  /// Formally audited and certified on-site by SUNASS/SEDAPAL emergency inspectors.
  verified;

  String get displayName {
    switch (this) {
      case ConfidenceLevel.unknown:
        return 'Confianza No Determinada';
      case ConfidenceLevel.low:
        return 'Confianza Baja (No Corroborado)';
      case ConfidenceLevel.medium:
        return 'Confianza Media (Múltiples Reportes)';
      case ConfidenceLevel.high:
        return 'Confianza Alta (Operador / Fuente Oficial)';
      case ConfidenceLevel.verified:
        return 'Verificado en Terreno';
    }
  }

  /// Numerical ordinal rank for sorting and comparison (0 = lowest, 4 = highest).
  int get rank {
    switch (this) {
      case ConfidenceLevel.unknown:
        return 0;
      case ConfidenceLevel.low:
        return 1;
      case ConfidenceLevel.medium:
        return 2;
      case ConfidenceLevel.high:
        return 3;
      case ConfidenceLevel.verified:
        return 4;
    }
  }

  static ConfidenceLevel fromString(String? value) {
    if (value == null) return ConfidenceLevel.unknown;
    switch (value.trim().toUpperCase()) {
      case 'LOW':
      case 'BAJA':
        return ConfidenceLevel.low;
      case 'MEDIUM':
      case 'MEDIA':
        return ConfidenceLevel.medium;
      case 'HIGH':
      case 'ALTA':
        return ConfidenceLevel.high;
      case 'VERIFIED':
      case 'VERIFICADO':
        return ConfidenceLevel.verified;
      case 'UNKNOWN':
      case 'DESCONOCIDO':
      default:
        return ConfidenceLevel.unknown;
    }
  }
}
