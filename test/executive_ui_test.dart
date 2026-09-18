import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aguacion_app/core/constants/app_colors.dart';
import 'package:aguacion_app/presentation/providers/app_state_provider.dart';
import 'package:aguacion_app/presentation/screens/home/inicio_tab.dart';
import 'package:aguacion_app/presentation/screens/more/more_tab.dart';
import 'package:aguacion_app/presentation/screens/points/points_tab.dart';
import 'package:aguacion_app/presentation/widgets/bottom_nav_bar.dart';
import 'package:aguacion_app/presentation/widgets/header_bar.dart';
import 'package:aguacion_app/presentation/widgets/operational_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fakes/fake_connectivity_service.dart';

Widget createTestApp(Widget child, {AppStateProvider? customProvider}) {
  final provider =
      customProvider ??
      AppStateProvider(connectivityService: FakeConnectivityService());
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

  group('Executive UI/UX V1 Tests', () {
    testWidgets(
      '1. HeaderBar displays clean institutional identity without technical POC labels',
      (tester) async {
        await tester.pumpWidget(createTestApp(const HeaderBar()));

        // Institutional branding & title
        expect(find.text('AguaCION'), findsOneWidget);
        expect(find.text('SUNASS'), findsOneWidget);

        // Clean citizen connectivity chip (defaults to En Línea or Modo Local)
        expect(find.text('En Línea'), findsOneWidget);

        // Must NOT contain technical POC labels
        expect(find.text('POC OFFLINE'), findsNothing);
        expect(find.text('Benchmark'), findsNothing);
        expect(find.text('CSR'), findsNothing);
        expect(find.text('A*'), findsNothing);
      },
    );

    testWidgets(
      '2. InicioTab displays executive hero card and offline status indicators',
      (tester) async {
        await tester.pumpWidget(createTestApp(const InicioTab()));

        // Hero Card
        expect(
          find.text('Encuentra puntos de abastecimiento incluso sin conexión'),
          findsOneWidget,
        );
        expect(find.text('ENCONTRAR PUNTO CERCANO'), findsOneWidget);
        expect(find.text('VER MAPA COMPLETO'), findsOneWidget);

        // Offline Ready status
        expect(find.text('Mapa offline'), findsOneWidget);
        expect(find.text('LISTO'), findsOneWidget);
        expect(
          find.textContaining('datos almacenados en el dispositivo'),
          findsWidgets,
        );
        expect(find.text('GUARDADOS'), findsOneWidget);

        // Quick Access Hub
        expect(find.text('Puntos de Agua'), findsOneWidget);
        expect(find.text('Mi Sector'), findsOneWidget);
        expect(find.text('Agua Segura'), findsOneWidget);

        // Institutional footer note
        expect(find.textContaining('SUNASS'), findsWidgets);
      },
    );

    testWidgets('3. BottomNavBar provides exactly 4 primary destinations', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const BottomNavBar()));

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Puntos'), findsOneWidget);
      expect(find.text('Más'), findsOneWidget);

      // Verify legacy 5-tab items are removed from primary bar
      expect(find.text('Reportar'), findsNothing);
      expect(find.text('Agua Segura'), findsNothing);
    });

    testWidgets(
      '4. PointsTab provides honest operational chips and search placeholder',
      (tester) async {
        final provider = AppStateProvider(
          connectivityService: FakeConnectivityService(),
        );
        await provider.loadCatalog();
        await tester.pumpWidget(
          createTestApp(const PointsTab(), customProvider: provider),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Search placeholder
        expect(find.text('Buscar distrito, parque o punto...'), findsOneWidget);

        // Filter chips: No unverified "Con agua" filter
        expect(find.textContaining('Todos'), findsOneWidget);
        expect(find.text('Cisternas'), findsOneWidget);
        expect(find.text('Piletas'), findsOneWidget);
        expect(find.text('Con agua'), findsNothing);

        // Honest operational status chips
        expect(find.byType(OperationalStatusChip), findsWidgets);
        expect(find.byType(SourceChip), findsWidgets);
        expect(find.text('Estado no confirmado'), findsWidgets);
        expect(find.text('Catálogo local'), findsWidgets);

        // Must NOT claim unverified live water status
        expect(find.textContaining('activa ahora mismo'), findsNothing);
      },
    );

    testWidgets('5. MoreTab renders secondary services and official about dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const MoreTab()));

      expect(find.text('Preparación de Agua'), findsOneWidget);
      expect(find.text('Mi Sector'), findsOneWidget);
      expect(find.textContaining('Reportar Incidencia'), findsOneWidget);
      expect(find.text('Acerca de AguaCION'), findsOneWidget);
    });
  });
}
