import 'package:geolocator/geolocator.dart';
import '../../data/models/user_location.dart';

class LocationService {
  /// Check permissions and get live GPS coordinates
  static Future<UserLocation?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return UserLocation(
        nombre: 'Ubicación GPS Actual',
        sector: 'Sector Detectado',
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
