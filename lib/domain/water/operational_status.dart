/// Technical operational status of a water supply point during an emergency observation.
///
/// NOTE: This is a TECHNICAL enum for system modeling, NOT an institutional policy statement.
/// Under zero circumstances should an official string like `Situación = Operativo`
/// be blindly or automatically mapped to [operational], because in official data
/// 111 points are simultaneously marked `Operativo` and `En reserva` (closed / standby).
enum OperationalStatus {
  /// The operational status has not been confirmed or no reliable report has been received.
  unknown,

  /// The point has been confirmed to be actively dispensing water to citizens.
  operational,

  /// The point is functioning under restrictions (e.g. rationed quotas, reduced hours, limited pressure).
  limited,

  /// The point is temporarily not serving (e.g. waiting for power generator refuel, valve maintenance, shift change).
  temporarilyUnavailable,

  /// The point is confirmed closed or out of service for the remainder of the active operational period.
  closed;

  String get displayName {
    switch (this) {
      case OperationalStatus.unknown:
        return 'Estado No Confirmado';
      case OperationalStatus.operational:
        return 'Operativo';
      case OperationalStatus.limited:
        return 'Operación Limitada';
      case OperationalStatus.temporarilyUnavailable:
        return 'Temporalmente No Disponible';
      case OperationalStatus.closed:
        return 'Cerrado';
    }
  }

  /// Whether this status indicates potential citizen service.
  bool get isPotentiallyServicing =>
      this == OperationalStatus.operational ||
      this == OperationalStatus.limited;

  static OperationalStatus fromString(String? value) {
    if (value == null) return OperationalStatus.unknown;
    switch (value.trim().toUpperCase()) {
      case 'OPERATIONAL':
      case 'OPERATIVO':
        return OperationalStatus.operational;
      case 'LIMITED':
      case 'LIMITADO':
        return OperationalStatus.limited;
      case 'TEMPORARILY_UNAVAILABLE':
      case 'TEMPORALMENTE_NO_DISPONIBLE':
        return OperationalStatus.temporarilyUnavailable;
      case 'CLOSED':
      case 'CERRADO':
        return OperationalStatus.closed;
      case 'UNKNOWN':
      case 'DESCONOCIDO':
      default:
        return OperationalStatus.unknown;
    }
  }
}
