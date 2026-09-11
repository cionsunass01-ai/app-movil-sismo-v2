import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/gnss_state.dart';

class OfflineLocationService {
  /// Attempts to obtain an offline GNSS position with progressive fallback:
  /// 1. Immediately queries [getLastKnownPosition] for instant display.
  /// 2. Attempts [getCurrentPosition] with a flexible timeout ([timeoutSeconds], default 30s).
  /// 3. Returns explicit [GnssPosition] with state and accuracy metrics.
  static Future<GnssPosition> acquirePosition({
    int timeoutSeconds = 30,
    void Function(String progressMessage)? onProgress,
  }) async {
    onProgress?.call('Verificando servicios de ubicación del dispositivo...');

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return const GnssPosition(
        latitude: -12.0453,
        longitude: -77.0311,
        state: LocationState.serviceDisabled,
        message:
            'El GPS del dispositivo está desactivado. Actívelo en Configuración.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const GnssPosition(
          latitude: -12.0453,
          longitude: -77.0311,
          state: LocationState.permissionDenied,
          message: 'Permiso de ubicación denegado por el usuario.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const GnssPosition(
        latitude: -12.0453,
        longitude: -77.0311,
        state: LocationState.permissionDenied,
        message: 'Permiso de ubicación permanentemente denegado.',
      );
    }

    // Step 1: Check last known position (essential for instant cold start in offline blackout)
    Position? lastPosition;
    try {
      lastPosition = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    onProgress?.call(
      'Sincronizando constelaciones de satélites GNSS (GPS/Galileo)...',
    );

    // Step 2: Acquire fresh hardware position without 5-second crash
    try {
      final freshPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: timeoutSeconds),
        ),
      );

      return GnssPosition(
        latitude: freshPosition.latitude,
        longitude: freshPosition.longitude,
        accuracyMeters: freshPosition.accuracy,
        timestamp: freshPosition.timestamp,
        state: LocationState.current,
        message: 'Posición GNSS actual obtenida con éxito.',
      );
    } on TimeoutException {
      // Step 3: If fresh fix timed out (cold start in urban canyons), fallback to last known
      if (lastPosition != null) {
        return GnssPosition(
          latitude: lastPosition.latitude,
          longitude: lastPosition.longitude,
          accuracyMeters: lastPosition.accuracy,
          timestamp: lastPosition.timestamp,
          state: LocationState.lastKnown,
          message:
              'Tiempo de espera GNSS agotado. Usando última posición conocida.',
        );
      }

      return GnssPosition(
        latitude: -12.0453, // Centro de Lima fallback
        longitude: -77.0311,
        state: LocationState.unavailable,
        message:
            'Sin señal de satélites GNSS tras $timeoutSeconds s de búsqueda a cielo abierto.',
      );
    } catch (e) {
      if (lastPosition != null) {
        return GnssPosition(
          latitude: lastPosition.latitude,
          longitude: lastPosition.longitude,
          accuracyMeters: lastPosition.accuracy,
          timestamp: lastPosition.timestamp,
          state: LocationState.lastKnown,
          message: 'Error de señal. Mostrando última posición registrada.',
        );
      }

      return GnssPosition(
        latitude: -12.0453,
        longitude: -77.0311,
        state: LocationState.unavailable,
        message: 'Error al consultar el subsistema GNSS: $e',
      );
    }
  }
}
