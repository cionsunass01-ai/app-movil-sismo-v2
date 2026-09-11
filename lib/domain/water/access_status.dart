/// Physical and security accessibility of the terrain / gates leading to a water point.
///
/// NOTE: This describes physical passage status during disaster conditions
/// (e.g. debris, cordoned area, open gate), distinct from disability/wheelchair accessibility.
enum AccessStatus {
  /// Physical access conditions are unknown or unverified.
  unknown,

  /// Approach path and perimeter entry are clear and safely passable on foot.
  accessible,

  /// Approach path is partially obstructed (e.g. narrow passage through rubble)
  /// or access is subject to police/military checkpoints.
  restricted,

  /// Approach path is completely impassable (e.g. collapsed bridge, severe landslide, flooded street).
  blocked,

  /// The entry gate or facility perimeter is locked or closed.
  closed;

  String get displayName {
    switch (this) {
      case AccessStatus.unknown:
        return 'Acceso No Verificado';
      case AccessStatus.accessible:
        return 'Acceso Peatonal Despejado';
      case AccessStatus.restricted:
        return 'Acceso Restringido / Con Dificultad';
      case AccessStatus.blocked:
        return 'Acceso Bloqueado / Impracticable';
      case AccessStatus.closed:
        return 'Portón o Entrada Cerrada';
    }
  }

  /// Whether citizens can physically reach the point on foot.
  bool get isPassable =>
      this == AccessStatus.accessible || this == AccessStatus.restricted;

  static AccessStatus fromString(String? value) {
    if (value == null) return AccessStatus.unknown;
    switch (value.trim().toUpperCase()) {
      case 'ACCESSIBLE':
      case 'DESPEJADO':
      case 'LIBRE':
        return AccessStatus.accessible;
      case 'RESTRICTED':
      case 'RESTRINGIDO':
        return AccessStatus.restricted;
      case 'BLOCKED':
      case 'BLOQUEADO':
        return AccessStatus.blocked;
      case 'CLOSED':
      case 'CERRADO':
        return AccessStatus.closed;
      case 'UNKNOWN':
      case 'DESCONOCIDO':
      default:
        return AccessStatus.unknown;
    }
  }
}
