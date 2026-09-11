/// Identifies the provenance or origin of an operational state, observation, or incident.
enum SourceType {
  /// Verified directly by SUNASS emergency regulatory monitoring teams.
  officialSunass,

  /// Published or verified by SEDAPAL operational emergency management systems.
  officialSedapal,

  /// Emergency Operations Center (COEN / COES / INDECI).
  coe,

  /// Verified field personnel or accredited NGO / municipal water distribution operator.
  accreditedOperator,

  /// Unverified or aggregated report submitted by a citizen via the mobile app.
  citizenReport,

  /// Derived by algorithmic calculation, spatio-temporal extrapolation, or machine inference.
  systemInference,

  /// Local test harness, developer demo, or synthetic simulation.
  /// CRITICAL: Under NO circumstances should LOCAL_SIMULATION data ever be presented as authentic!
  localSimulation;

  String get displayName {
    switch (this) {
      case SourceType.officialSunass:
        return 'Oficial SUNASS';
      case SourceType.officialSedapal:
        return 'Oficial SEDAPAL';
      case SourceType.coe:
        return 'Centro de Operaciones de Emergencia (COE)';
      case SourceType.accreditedOperator:
        return 'Operador Acreditado en Campo';
      case SourceType.citizenReport:
        return 'Reporte Ciudadano';
      case SourceType.systemInference:
        return 'Inferencia del Sistema';
      case SourceType.localSimulation:
        return 'Simulación Local de Prueba';
    }
  }

  /// Whether this source has formal institutional standing.
  bool get isOfficial =>
      this == SourceType.officialSunass ||
      this == SourceType.officialSedapal ||
      this == SourceType.coe;

  /// Whether this is a synthetic simulation that must be explicitly flagged in UI and logs.
  bool get isSimulated => this == SourceType.localSimulation;

  /// Whether this originated from a citizen mobile report.
  bool get isCitizen => this == SourceType.citizenReport;

  static SourceType fromString(String? value) {
    if (value == null) return SourceType.systemInference;
    final normalized = value.trim().replaceAll('_', '').toUpperCase();
    switch (normalized) {
      case 'OFFICIALSUNASS':
      case 'SUNASS':
        return SourceType.officialSunass;
      case 'OFFICIALSEDAPAL':
      case 'SEDAPAL':
        return SourceType.officialSedapal;
      case 'COE':
      case 'INDECI':
      case 'COEN':
        return SourceType.coe;
      case 'ACCREDITEDOPERATOR':
      case 'OPERADOR':
        return SourceType.accreditedOperator;
      case 'CITIZENREPORT':
      case 'CIUDADANO':
        return SourceType.citizenReport;
      case 'SYSTEMINFERENCE':
      case 'INFERENCIA':
        return SourceType.systemInference;
      case 'LOCALSIMULATION':
      case 'SIMULACION':
        return SourceType.localSimulation;
      default:
        return SourceType.systemInference;
    }
  }
}
