import 'dart:math';

class GeoUtils {
  /// Calculates great-circle distance between two coordinates in meters (Haversine formula)
  static int calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (earthRadiusMeters * c).round();
  }

  /// Formats distance in meters or kilometers (e.g. "180 m" or "1,4 km")
  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    final double km = meters / 1000.0;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Formats estimated walking time based on disaster walking speed (~4 km/h = ~67 m/min)
  static String formatWalkingTime(int meters) {
    final int minutes = max(1, (meters / 67.0).round());
    if (minutes < 60) {
      return '$minutes min a pie';
    }
    final int hours = minutes ~/ 60;
    final int remMin = minutes % 60;
    return '${hours}h ${remMin}m a pie';
  }
}
