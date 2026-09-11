/// Configurable policy for citizen report corroboration in operational assessment.
///
/// ARCHITECTURAL MANDATE (Hito 3A Corrective Closure):
/// Thresholds like "5 reports in 45 min" are NOT institutionally validated rules.
/// They must remain configurable, default to unconfigured, and marked PENDING_INSTITUTIONAL_VALIDATION.
class CitizenCorroborationPolicy {
  final int? minimumReports;
  final Duration? timeWindow;
  final bool isSimulationOrDemo;

  const CitizenCorroborationPolicy({
    this.minimumReports,
    this.timeWindow,
    this.isSimulationOrDemo = false,
  });

  /// Default baseline posture: institutional rules for citizen report aggregation
  /// are PENDING_INSTITUTIONAL_VALIDATION.
  static const CitizenCorroborationPolicy unconfigured =
      CitizenCorroborationPolicy(
        minimumReports: null,
        timeWindow: null,
        isSimulationOrDemo: false,
      );

  /// Synthetic demo policy for testing only (NOT INSTITUTIONALLY VALIDATED).
  static const CitizenCorroborationPolicy demoSimulation =
      CitizenCorroborationPolicy(
        minimumReports: 5,
        timeWindow: Duration(minutes: 45),
        isSimulationOrDemo: true,
      );

  /// Whether aggregation thresholds are explicitly configured.
  bool get isConfigured => minimumReports != null && timeWindow != null;
}
