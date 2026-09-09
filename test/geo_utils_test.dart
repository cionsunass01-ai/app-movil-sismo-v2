import 'package:flutter_test/flutter_test.dart';
import 'package:aguacion_app/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils Tests', () {
    test('calculateDistanceMeters returns accurate Haversine distance', () {
      // Plaza de Armas Moquegua to Parque Mariscal Nieto (~180m)
      final dist = GeoUtils.calculateDistanceMeters(-17.1950, -70.9345, -17.1938, -70.9356);
      expect(dist, inInclusiveRange(150, 200));
    });

    test('formatDistance formats correctly for meters and kilometers', () {
      expect(GeoUtils.formatDistance(180), '180 m');
      expect(GeoUtils.formatDistance(1400), '1,4 km');
    });

    test('formatWalkingTime estimates ~4 km/h walking time accurately', () {
      expect(GeoUtils.formatWalkingTime(180), '3 min a pie');
      expect(GeoUtils.formatWalkingTime(5000), '1h 15m a pie');
    });
  });
}
