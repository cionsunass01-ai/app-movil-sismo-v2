import 'freshness.dart';

/// Configurable policy that defines temporal freshness boundaries for operational observations.
///
/// ARCHITECTURAL MANDATE (Hito 3A Corrective Closure):
/// TTLs are NEVER hardcoded as productive rules without institutional validation from SUNASS/SEDAPAL.
/// All thresholds are fully configurable and default to unconfigured ([FreshnessState.policyNotConfigured]).
/// Any threshold set used for local testing or demos is strictly flagged as [isSimulationOrDemo].
class FreshnessPolicy {
  final String policyName;
  final Duration? freshDuration;
  final Duration? agingDuration;
  final Duration? staleDuration;
  final bool isSimulationOrDemo;

  const FreshnessPolicy({
    required this.policyName,
    this.freshDuration,
    this.agingDuration,
    this.staleDuration,
    this.isSimulationOrDemo = false,
  });

  /// Default institutional baseline posture: policy has NOT been established or validated.
  static const FreshnessPolicy unconfigured = FreshnessPolicy(
    policyName: 'POLICY_NOT_CONFIGURED',
    freshDuration: null,
    agingDuration: null,
    staleDuration: null,
    isSimulationOrDemo: false,
  );

  /// Productive default returns unconfigured policy until SUNASS/SEDAPAL establish official rules.
  factory FreshnessPolicy.standard() => unconfigured;

  /// Synthetic simulation policy strictly for local tests and demos.
  /// CRITICAL: NOT VALIDATED BY SUNASS/SEDAPAL (EXAMPLE ONLY — NOT INSTITUTIONALLY VALIDATED).
  static const FreshnessPolicy demoSimulation = FreshnessPolicy(
    policyName: 'LOCAL_SIMULATION_DEMO_ONLY',
    freshDuration: Duration(hours: 1),
    agingDuration: Duration(hours: 3),
    staleDuration: Duration(hours: 6),
    isSimulationOrDemo: true,
  );

  /// Whether this policy has all duration thresholds explicitly defined.
  bool get isConfigured =>
      freshDuration != null && agingDuration != null && staleDuration != null;

  /// Evaluates the [FreshnessState] of an observation given its [updatedAt],
  /// optional explicit [validUntil], and reference evaluation time [referenceTime].
  FreshnessState evaluate({
    required DateTime? updatedAt,
    DateTime? validUntil,
    DateTime? referenceTime,
    DateTime? now,
  }) {
    if (updatedAt == null) return FreshnessState.unknown;

    final currentTime = referenceTime ?? now ?? DateTime.now();

    // Explicit validUntil cutoff takes precedence: if expired, it is expired.
    if (validUntil != null && currentTime.isAfter(validUntil)) {
      return FreshnessState.expired;
    }

    // If thresholds have not been institutionally established, state is unconfigured
    if (!isConfigured) {
      return FreshnessState.policyNotConfigured;
    }

    final age = currentTime.difference(updatedAt);
    if (age.isNegative) {
      // Future timestamp anomaly
      return FreshnessState.unknown;
    }

    if (age <= freshDuration!) {
      return FreshnessState.fresh;
    } else if (age <= agingDuration!) {
      return FreshnessState.aging;
    } else if (age <= staleDuration!) {
      return FreshnessState.stale;
    } else {
      return FreshnessState.expired;
    }
  }

  /// Formats human-readable elapsed time string (e.g. "hace 45 min", "hace 3 h").
  static String formatElapsed(DateTime updatedAt, [DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(updatedAt);

    if (diff.inSeconds < 60) {
      return 'hace menos de un minuto';
    } else if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'hace ${diff.inHours} h';
    } else {
      return 'hace ${diff.inDays} d';
    }
  }
}
