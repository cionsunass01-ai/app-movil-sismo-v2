/// Explainable rationale behind a recommendation, alternative suggestion, or candidate ranking.
///
/// DESIGN RATIONALE (ADR-005):
/// Replaces opaque numeric scoring formulas ("magic scores") with discrete,
/// human-auditable and institutionally explainable reasons.
enum RecommendationReason {
  /// Physically closest reachable point via walking route.
  shortestWalkableRoute,

  /// Confirmed live availability of drinking water from a verified source.
  confirmedWaterAvailable,

  /// Significantly lower queue length or crowd saturation compared to nearby options.
  lowerQueueLevel,

  /// Information is more recent and within fresh operational validity.
  fresherInformation,

  /// Backed by an official authority (SUNASS/SEDAPAL/COE) or verified operator.
  higherConfidenceSource,

  /// Offered as an alternative because the closest point is confirmed closed or unreachable.
  alternativeDueToClosure,

  /// Offered as an alternative because the closest point has extreme queue saturation.
  alternativeDueToSaturation,

  /// Closest available walking candidate when no live operational status exists (offline fallback).
  closestWalkableUnverifiedState,

  /// Accessible for citizens with mobility challenges (wheelchair friendly / zero stairs).
  betterAccessibilityProfile;

  String get userExplanation {
    switch (this) {
      case RecommendationReason.shortestWalkableRoute:
        return 'Ruta a pie más corta y directa.';
      case RecommendationReason.confirmedWaterAvailable:
        return 'Disponibilidad de agua confirmada recientemente.';
      case RecommendationReason.lowerQueueLevel:
        return 'Menor tiempo de espera y menor saturación de cola.';
      case RecommendationReason.fresherInformation:
        return 'Reporte operacional más reciente y vigente.';
      case RecommendationReason.higherConfidenceSource:
        return 'Información validada por fuente oficial u operador acreditado.';
      case RecommendationReason.alternativeDueToClosure:
        return 'Sugerido como alternativa porque el punto más cercano está cerrado.';
      case RecommendationReason.alternativeDueToSaturation:
        return 'Sugerido como alternativa porque el punto más cercano está saturado.';
      case RecommendationReason.closestWalkableUnverifiedState:
        return 'Punto más cercano según infraestructura física (estado live no disponible).';
      case RecommendationReason.betterAccessibilityProfile:
        return 'Mejor perfil de accesibilidad para movilidad reducida.';
    }
  }
}

/// Disqualification or warning reasons explaining why a point was excluded or deprioritized.
enum ExclusionReason {
  confirmedClosed,
  confirmedEmpty,
  accessBlockedByIncident,
  noWalkableRouteFound,
  snappingExceededThreshold,
  retiredInfrastructure,
  outsideAuthorizedEmergencyZone;

  String get explanation {
    switch (this) {
      case ExclusionReason.confirmedClosed:
        return 'Punto confirmado cerrado u fuera de servicio.';
      case ExclusionReason.confirmedEmpty:
        return 'Punto reportado temporalmente sin agua.';
      case ExclusionReason.accessBlockedByIncident:
        return 'Vía de acceso peatonal bloqueada por un incidente activo.';
      case ExclusionReason.noWalkableRouteFound:
        return 'No existe ruta caminable navegable en el grafo disponible.';
      case ExclusionReason.snappingExceededThreshold:
        return 'Punto excede el umbral de conexión peatonal (50 m).';
      case ExclusionReason.retiredInfrastructure:
        return 'Infraestructura dada de baja o inactiva en el catastro.';
      case ExclusionReason.outsideAuthorizedEmergencyZone:
        return 'Fuera de la zona de abastecimiento institucionalmente autorizada.';
    }
  }
}
