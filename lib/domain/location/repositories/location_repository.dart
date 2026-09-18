import '../models/gnss_state.dart';

/// Abstract contract for location/GNSS services.
///
/// Implementations handle the platform-specific details of acquiring
/// GPS coordinates from hardware sensors (GNSS chip), including
/// permission management and fallback strategies.
abstract class LocationRepository {
  /// Attempts to obtain an offline GNSS position with progressive fallback:
  /// 1. Immediately queries last known position for instant display.
  /// 2. Attempts current position with a flexible timeout.
  /// 3. Returns explicit [GnssPosition] with state and accuracy metrics.
  Future<GnssPosition> acquirePosition({
    int timeoutSeconds = 30,
    bool requestIfNotGranted = true,
    void Function(String progressMessage)? onProgress,
  });
}
