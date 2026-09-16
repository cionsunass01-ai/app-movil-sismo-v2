import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aguacion_app/data/models/water_point.dart';
import 'package:aguacion_app/presentation/screens/points/point_detail_sheet.dart';

void main() {
  const double validLat = -12.0464;
  const double validLon = -77.0428;

  Map<String, dynamic> createBaseFixture({
    double? latitude = validLat,
    double? longitude = validLon,
    String id = 'WP-TEST-001',
    String? componentTypeNormalized,
    String? componentTypeRaw,
    dynamic capacity,
    String? capacityUnit,
    String? calidad,
    String? horario,
    String? recarga,
    dynamic pobl,
    String? acceso,
    String? pend,
    String? validFrom,
    String? fieldVerificationDate,
  }) {
    final map = <String, dynamic>{
      'water_point_id': id,
      'location_description': 'Punto de Prueba Honesto',
      'official_code': 'P-HONEST-01',
      'district': 'LIMA',
      'eomr': 'EOMR-CENTRO',
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (componentTypeNormalized != null) {
      map['component_type_normalized'] = componentTypeNormalized;
    }
    if (componentTypeRaw != null) {
      map['component_type_raw'] = componentTypeRaw;
    }
    if (capacity != null) map['capacity'] = capacity;
    if (capacityUnit != null) map['capacity_unit'] = capacityUnit;
    if (calidad != null) map['calidad'] = calidad;
    if (horario != null) map['horario'] = horario;
    if (recarga != null) map['recarga'] = recarga;
    if (pobl != null) map['pobl'] = pobl;
    if (acceso != null) map['acceso'] = acceso;
    if (pend != null) map['pend'] = pend;
    if (validFrom != null) map['valid_from'] = validFrom;
    if (fieldVerificationDate != null) {
      map['field_verification_date'] = fieldVerificationDate;
    }
    return map;
  }

  Widget createTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CATALOG DATA HONESTY SPECIFICATION (Hotfix Suite)', () {
    test('1. capacity sin unit no produce m³', () {
      final fixtureUnknownUnit = createBaseFixture(
        capacity: 100.0,
        capacityUnit: 'UNKNOWN',
      );
      final pointUnknown = WaterPoint.fromNormalizedJson(fixtureUnknownUnit);
      expect(pointUnknown.cap, isNot(contains('m³')));
      expect(pointUnknown.cap, equals('100'));

      final fixtureNoUnit = createBaseFixture(capacity: 25.5);
      final pointNoUnit = WaterPoint.fromNormalizedJson(fixtureNoUnit);
      expect(pointNoUnit.cap, isNot(contains('m³')));
      expect(pointNoUnit.cap, equals('25.5'));

      // If unit is explicitly valid, it is preserved
      final fixtureWithExplicitUnit = createBaseFixture(
        capacity: 100.0,
        capacityUnit: 'L/s',
      );
      final pointWithUnit = WaterPoint.fromNormalizedJson(
        fixtureWithExplicitUnit,
      );
      expect(pointWithUnit.cap, equals('100 L/s'));
    });

    test('2. unknown component type no produce cisterna', () {
      final fixtureCamara = createBaseFixture(
        componentTypeNormalized: 'CAMARA',
        componentTypeRaw: 'Cámara con manifold',
      );
      final pointCamara = WaterPoint.fromNormalizedJson(fixtureCamara);
      expect(pointCamara.tipo, isNot(equals(PointType.cisterna)));
      expect(pointCamara.tipo, equals(PointType.noEspecificado));
      expect(pointCamara.componentTypeRaw, equals('Cámara con manifold'));

      final fixtureEmpty = createBaseFixture();
      final pointEmpty = WaterPoint.fromNormalizedJson(fixtureEmpty);
      expect(pointEmpty.tipo, isNot(equals(PointType.cisterna)));
      expect(pointEmpty.tipo, equals(PointType.noEspecificado));
    });

    test('3. quality ausente no produce "apta"', () {
      final fixture = createBaseFixture();
      final point = WaterPoint.fromNormalizedJson(fixture);
      expect(point.calidad, isNot(equals(WaterQuality.apta)));
      expect(point.calidad, isNull);
    });

    test('4. access ausente no produce acceso inventado', () {
      final fixture = createBaseFixture();
      final point = WaterPoint.fromNormalizedJson(fixture);
      expect(point.acceso, isNull);
      expect(point.pend, isNull);
      expect(point.acceso, isNot(equals('Vía peatonal / vehicular')));
      expect(point.pend, isNot(equals('Normal')));
    });

    test('5. verification date ausente no crea fecha hardcodeada', () {
      final fixture = createBaseFixture(validFrom: '2026-08-19');
      final point = WaterPoint.fromNormalizedJson(fixture);
      // Field verification must be null if absent from source
      expect(point.ver, isNull);
      expect(point.verMeses, isNull);
      // valid_from is strictly dataset cutoff/source date
      expect(point.validFrom, equals('2026-08-19'));
    });

    test('6. population ausente no muestra 0 hab.', () {
      final fixture = createBaseFixture();
      final point = WaterPoint.fromNormalizedJson(fixture);
      expect(point.pobl, isNull);
      expect(point.pobl, isNot(equals(0)));
    });

    testWidgets('7. Haversine no muestra tiempo a pie', (tester) async {
      final point = WaterPoint.fromNormalizedJson(
        createBaseFixture(),
      ).copyWith(distMeters: 850, isDistanceApproximate: true);

      await tester.pumpWidget(
        createTestWidget(
          PointDetailSheet(
            point: point,
            isEmergency: false,
            onReportTapped: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Distancia aprox.'), findsWidgets);
      expect(find.textContaining('min a pie'), findsNothing);
    });

    testWidgets('8. routed distance sí muestra tiempo', (tester) async {
      final point = WaterPoint.fromNormalizedJson(
        createBaseFixture(),
      ).copyWith(distMeters: 850, isDistanceApproximate: false);

      await tester.pumpWidget(
        createTestWidget(
          PointDetailSheet(
            point: point,
            isEmergency: false,
            onReportTapped: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Distancia por ruta'), findsWidgets);
      expect(find.textContaining('min a pie'), findsWidgets);
    });

    testWidgets('9. PointDetailSheet no afirma agua apta sin evidencia', (
      tester,
    ) async {
      final point = WaterPoint.fromNormalizedJson(createBaseFixture());

      await tester.pumpWidget(
        createTestWidget(
          PointDetailSheet(
            point: point,
            isEmergency: false,
            onReportTapped: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Agua apta para consumo humano directo'), findsNothing);
      expect(
        find.text('Calidad del agua: Sin información actual'),
        findsOneWidget,
      );
    });

    testWidgets(
      '10. PointDetailSheet no afirma control de cloro/turbidez sin evidencia',
      (tester) async {
        final point = WaterPoint.fromNormalizedJson(createBaseFixture());

        await tester.pumpWidget(
          createTestWidget(
            PointDetailSheet(
              point: point,
              isEmergency: false,
              onReportTapped: () {},
            ),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('control de cloro residual y turbidez'),
          findsNothing,
        );
        expect(find.textContaining('SUNASS'), findsNothing);
      },
    );

    test('11. estado desconocido usa presentación neutral', () {
      final point = WaterPoint.fromNormalizedJson(createBaseFixture());
      expect(point.estE, equals(EmergencyStatus.unknown));
      expect(point.estETxt, equals('Estado no confirmado'));
      expect(point.estN, equals('Catálogo local'));
    });

    test('12. serialización nullable funciona', () {
      final point = WaterPoint.fromNormalizedJson(createBaseFixture());
      final jsonMap = point.toJson();
      final restored = WaterPoint.fromJson(jsonMap);

      expect(restored.id, equals(point.id));
      expect(restored.lat, equals(point.lat));
      expect(restored.lon, equals(point.lon));
      expect(restored.calidad, isNull);
      expect(restored.pobl, isNull);
      expect(restored.cap, isNull);
      expect(restored.horario, isNull);
      expect(restored.recarga, isNull);
      expect(restored.acceso, isNull);
      expect(restored.pend, isNull);
      expect(restored.ver, isNull);
      expect(restored.verMeses, isNull);
      expect(restored.estE, equals(EmergencyStatus.unknown));
    });

    test(
      '13. registro sin latitude/longitude NO termina convertido en 0.0,0.0',
      () {
        final jsonWithoutLat = createBaseFixture(
          latitude: null,
          longitude: validLon,
        );
        expect(
          () => WaterPoint.fromNormalizedJson(jsonWithoutLat),
          throwsA(isA<ArgumentError>()),
        );

        final jsonWithoutLon = createBaseFixture(
          latitude: validLat,
          longitude: null,
        );
        expect(
          () => WaterPoint.fromNormalizedJson(jsonWithoutLon),
          throwsA(isA<ArgumentError>()),
        );

        final jsonWithoutBoth = createBaseFixture(
          latitude: null,
          longitude: null,
        );
        expect(
          () => WaterPoint.fromNormalizedJson(jsonWithoutBoth),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
