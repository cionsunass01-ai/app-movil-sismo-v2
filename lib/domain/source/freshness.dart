/// Qualitative temporal state of an operational observation.
enum FreshnessState {
  /// Observation is recent and fully within the optimal validity window.
  fresh,

  /// Observation is starting to age but remains reasonably credible; a refresh is desirable.
  aging,

  /// Observation has exceeded the standard credibility window; MUST be flagged in UI with warnings.
  stale,

  /// Observation has passed its explicit [validUntil] cutoff or extreme lifespan; cannot be relied upon without re-verification.
  expired,

  /// Timestamp is missing, in the future, or cannot be verified.
  unknown,

  /// Freshness policy thresholds have not been institutionally established by SUNASS/SEDAPAL.
  policyNotConfigured;

  String get displayName {
    switch (this) {
      case FreshnessState.fresh:
        return 'Información Reciente (Fresca)';
      case FreshnessState.aging:
        return 'Información En Envejecimiento';
      case FreshnessState.stale:
        return 'Información Desactualizada';
      case FreshnessState.expired:
        return 'Información Vencida / Expirada';
      case FreshnessState.unknown:
        return 'Vigencia Desconocida';
      case FreshnessState.policyNotConfigured:
        return 'Política de Vigencia No Configurada';
    }
  }

  /// Whether the information can still be consulted by citizens (with or without warnings).
  bool get isUsable =>
      this == FreshnessState.fresh ||
      this == FreshnessState.aging ||
      this == FreshnessState.stale ||
      this == FreshnessState.policyNotConfigured;

  /// Whether the UI MUST display an explicit freshness warning banner to the citizen.
  bool get requiresWarningBanner =>
      this == FreshnessState.stale ||
      this == FreshnessState.expired ||
      this == FreshnessState.policyNotConfigured;
}
