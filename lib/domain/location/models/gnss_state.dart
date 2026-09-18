enum LocationState {
  acquiring,
  current,
  lastKnown,
  unavailable,
  permissionDenied,
  serviceDisabled,
}

class GnssPosition {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? timestamp;
  final LocationState state;
  final String message;

  const GnssPosition({
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.message,
    this.accuracyMeters,
    this.timestamp,
  });

  bool get isValid =>
      state == LocationState.current || state == LocationState.lastKnown;

  String get elapsedDescription {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds} s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    return 'hace ${diff.inHours} h';
  }

  String get statusDisplay {
    switch (state) {
      case LocationState.acquiring:
        return 'Sincronizando satélites GNSS...';
      case LocationState.current:
        final acc = accuracyMeters != null
            ? ' (±${accuracyMeters!.toStringAsFixed(1)} m)'
            : '';
        return 'Ubicación GPS en tiempo real$acc';
      case LocationState.lastKnown:
        return 'Última ubicación conocida — $elapsedDescription';
      case LocationState.permissionDenied:
        return 'Permiso de ubicación denegado';
      case LocationState.serviceDisabled:
        return 'Servicio de GPS desactivado en el dispositivo';
      case LocationState.unavailable:
        return 'Ubicación no disponible sin señal';
    }
  }
}
