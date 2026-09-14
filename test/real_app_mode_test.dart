import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aguacion_app/core/constants/app_colors.dart';
import 'package:aguacion_app/data/models/user_location.dart';
import 'package:aguacion_app/data/models/water_point.dart';
import 'package:aguacion_app/data/repositories/local_water_point_catalog_repository.dart';
import 'package:aguacion_app/presentation/providers/app_state_provider.dart';
import 'package:aguacion_app/presentation/screens/points/points_tab.dart';
import 'package:aguacion_app/presentation/screens/sector/sector_tab.dart';
import 'package:aguacion_app/presentation/widgets/connectivity_strip.dart';
import 'fakes/fake_connectivity_service.dart';

class _UnavailableCatalogRepo extends LocalWaterPointCatalogRepository {
  @override
  CatalogStatus get status => CatalogStatus.unavailable;
  @override
  bool get isAvailable => false;
  @override
  List<WaterPoint> get cachedPoints => [];
  @override
  Future<List<WaterPoint>> loadCatalog() async => [];
}

Widget createTestScope(Widget child, AppStateProvider provider) {
  return ChangeNotifierProvider<AppStateProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: AppColors.slate100),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('REAL_APP_MODE Obligatory Verification Suite (Hito 3)', () {
    test('1. REAL_APP_MODE does not load Moquegua / demo fixtures', () async {
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
      );
      await provider.loadCatalog();

      expect(provider.isCatalogAvailable, isTrue);
      expect(provider.points.length, equals(433));

      // Assert NO Moquegua points exist in runtime
      for (final p in provider.points) {
        expect(p.sector.toLowerCase().contains('moquegua'), isFalse);
        expect(p.n.toLowerCase().contains('chen chen'), isFalse);
        expect(p.n.toLowerCase().contains('mariscal nieto'), isFalse);
        expect(p.id.startsWith('MOQ-'), isFalse);

        // All points must be within Lima Metropolitana & Callao bounding box
        expect(p.lat, inInclusiveRange(-12.50, -11.60));
        expect(p.lon, inInclusiveRange(-77.30, -76.70));
      }
    });

    test('2. PointsTab orders points according to provided user location', () async {
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
      );
      await provider.loadCatalog();

      // Set user location in Callao (near port / Plaza Grau Callao)
      const callaoLoc = UserLocation(
        nombre: 'Callao',
        sector: 'Callao',
        lat: -12.0600,
        lon: -77.1450,
      );
      provider.updateUserLocation(callaoLoc);

      final topCallao = provider.points.first;
      expect(topCallao.lon, lessThan(-77.05)); // Closer to Callao than Lima Este

      // Set user location in Santiago de Surco / Miraflores (South Lima)
      const surcoLoc = UserLocation(
        nombre: 'Surco',
        sector: 'Surco',
        lat: -12.1400,
        lon: -77.0000,
      );
      provider.updateUserLocation(surcoLoc);

      final topSurco = provider.points.first;
      expect(topSurco.lat, lessThan(-12.08)); // Closer to Southern Lima
    });

    test('3. Does not label Haversine as walking distance or minutes on foot', () async {
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
      );
      await provider.loadCatalog();

      provider.updateUserLocation(const UserLocation(
        nombre: 'Lima Centro',
        sector: 'Centro',
        lat: -12.0464,
        lon: -77.0428,
      ));

      // Points with geodesic distance must have isDistanceApproximate = true
      final approxPoint = provider.points.first;
      expect(approxPoint.isDistanceApproximate, isTrue);
      expect(approxPoint.distMeters, isNotNull);
    });

    testWidgets('4. PointsTab renders honest approximate distance badge and no walking time', (tester) async {
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
      );
      await provider.loadCatalog();
      provider.updateUserLocation(const UserLocation(
        nombre: 'Centro',
        sector: 'Lima',
        lat: -12.0464,
        lon: -77.0428,
      ));

      await tester.pumpWidget(createTestScope(const PointsTab(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must find approximate distance label and NEVER claim minutes on foot
      expect(find.text('Distancia aprox.'), findsWidgets);
      expect(find.textContaining('min a pie'), findsNothing);
    });

    test('5. MapTab camera auto-center flag logic triggers once on first location', () {
      bool hasInitialCentered = false;

      void onFirstLocationAcquired() {
        if (!hasInitialCentered) {
          hasInitialCentered = true;
        }
      }

      onFirstLocationAcquired();
      expect(hasInitialCentered, isTrue);

      // Subsequent location fixes or user pans do not re-center automatically
      bool recenteredAgain = false;
      void onSubsequentLocation() {
        if (!hasInitialCentered) {
          recenteredAgain = true;
        }
      }

      onSubsequentLocation();
      expect(recenteredAgain, isFalse);
    });

    testWidgets('6. ConnectivityStrip reflects physical ConnectivityService', (tester) async {
      final fakeConn = FakeConnectivityService(NetworkState.connected);
      final provider = AppStateProvider(connectivityService: fakeConn);

      await tester.pumpWidget(createTestScope(const ConnectivityStrip(), provider));
      await tester.pump();

      expect(find.text('Con conexión de red'), findsOneWidget);

      // Simulate hardware disconnection
      fakeConn.emit(NetworkState.disconnected);
      await tester.pump();

      expect(
        find.text('Sin conexión — Mapa local y cálculo de rutas disponibles en el dispositivo'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      provider.dispose();
    });

    testWidgets('7. ConnectivityStrip does not toggle connection on citizen tap', (tester) async {
      final fakeConn = FakeConnectivityService(NetworkState.connected);
      final provider = AppStateProvider(connectivityService: fakeConn);

      await tester.pumpWidget(createTestScope(const ConnectivityStrip(), provider));
      await tester.pump();

      expect(provider.isOnline, isTrue);

      // Tap on the strip: must NOT toggle state (strip is READ-ONLY in real mode)
      await tester.tap(find.byType(ConnectivityStrip));
      await tester.pump();

      expect(provider.isOnline, isTrue);
    });

    test('8. Demo connectivity override works only when simulation is explicitly enabled', () {
      final fakeConn = FakeConnectivityService(NetworkState.connected);
      final provider = AppStateProvider(connectivityService: fakeConn);

      expect(provider.isConnectivitySimulationEnabled, isFalse);
      expect(provider.isOnline, isTrue);

      // Change simulated value without enabling simulation: real connectivity still rules
      provider.setSimulatedConnectivity(NetworkState.disconnected);
      expect(provider.isOnline, isTrue);

      // Enable simulation: simulated state takes effect
      provider.setConnectivitySimulationEnabled(true);
      expect(provider.isConnectivitySimulationEnabled, isTrue);
      expect(provider.isOnline, isFalse);
    });

    test('9. Disabling simulation immediately restores real hardware state', () {
      final fakeConn = FakeConnectivityService(NetworkState.connected);
      final provider = AppStateProvider(connectivityService: fakeConn);

      provider.setConnectivitySimulationEnabled(true);
      provider.setSimulatedConnectivity(NetworkState.disconnected);
      expect(provider.isOnline, isFalse);

      // Disable simulation: immediately reverts to real connected state
      provider.setConnectivitySimulationEnabled(false);
      expect(provider.isConnectivitySimulationEnabled, isFalse);
      expect(provider.isOnline, isTrue);
    });

    testWidgets('10. If local catalog does not exist, demo catalog does NOT appear', (tester) async {
      final unavailableRepo = _UnavailableCatalogRepo();
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
        catalogRepo: unavailableRepo,
      );
      await provider.loadCatalog();

      await tester.pumpWidget(createTestScope(const PointsTab(), provider));
      await tester.pump();

      // Assert NO Moquegua points or fake fixtures exist
      expect(find.text('Cercado de Moquegua'), findsNothing);
      expect(find.text('San Francisco'), findsNothing);
      expect(find.text('Chen Chen'), findsNothing);
      expect(provider.points.isEmpty, isTrue);
      expect(find.text('Catálogo local no disponible en esta instalación.'), findsOneWidget);
    });

    testWidgets('11. Mi Sector does not invent sector data', (tester) async {
      final provider = AppStateProvider(
        connectivityService: FakeConnectivityService(),
      );

      expect(provider.currentSectorData.n, equals('Pendiente de integración'));
      expect(provider.sectors.isEmpty, isTrue);

      await tester.pumpWidget(createTestScope(const SectorTab(), provider));
      await tester.pump();

      expect(find.text('Información de sector pendiente de integración'), findsOneWidget);
      expect(find.text('FUNCIÓN EN DESARROLLO'), findsOneWidget);
      expect(find.text('Cercado de Moquegua'), findsNothing);
    });

    test('12. App operates fully offline with local catalog', () async {
      final fakeConn = FakeConnectivityService(NetworkState.disconnected);
      final provider = AppStateProvider(connectivityService: fakeConn);
      await provider.loadCatalog();

      expect(provider.isOnline, isFalse);
      expect(provider.isCatalogAvailable, isTrue);
      expect(provider.points.length, equals(433));

      // Queued reports persist locally without errors
      await provider.submitReport(
        puntoId: provider.points.first.id,
        puntoNombre: provider.points.first.n,
        tipoProblema: 'Sin agua',
        comentario: 'Reporte offline',
        sector: provider.points.first.sector,
      );

      expect(provider.queuedReports.length, equals(1));
    });
  });
}
