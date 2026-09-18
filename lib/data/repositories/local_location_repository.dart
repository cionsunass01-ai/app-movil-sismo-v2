import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../../domain/location/models/gnss_state.dart';
import '../../../../domain/location/repositories/location_repository.dart';

/// Concrete implementation of [LocationRepository] using the geolocator package
/// to acquire GNSS positions from the device hardware sensor.
class LocalLocationRepository implements LocationRepository {
  @override
  Future<GnssPosition> acquirePosition({
    int timeoutSeconds = 30,
    bool requestIfNotGranted = true,
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
      if (!requestIfNotGranted) {
        return const GnssPosition(
          latitude: -12.0453,
          longitude: -77.0311,
          state: LocationState.unavailable,
          message: 'Permiso de ubicación pendiente de autorización.',
        );
      }
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
