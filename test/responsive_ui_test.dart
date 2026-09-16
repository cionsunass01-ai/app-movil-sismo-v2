import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aguacion_app/core/constants/app_colors.dart';
import 'package:aguacion_app/presentation/providers/app_state_provider.dart';
import 'package:aguacion_app/presentation/screens/home/inicio_tab.dart';
import 'package:aguacion_app/presentation/screens/more/more_tab.dart';
import 'package:aguacion_app/presentation/screens/points/points_tab.dart';
import 'package:aguacion_app/presentation/screens/main_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'fakes/fake_connectivity_service.dart';

Widget createSizedBoxApp(
  Widget child,
  Size size, {
  AppStateProvider? customProvider,
}) {
  final provider =
      customProvider ??
      AppStateProvider(connectivityService: FakeConnectivityService());
  return ChangeNotifierProvider<AppStateProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: AppColors.slate100),
      home: Material(
        color: AppColors.slate100,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Responsive Layout Verification (Zero Overflow)', () {
    const sizes = [
      Size(360, 800), // Standard Android (Samsung A5x, S24 compact)
      Size(390, 844), // Standard iOS (iPhone 12 / 13 / 14 / 15 / 16)
    ];

    for (final size in sizes) {
      testWidgets(
        'InicioTab renders cleanly at ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(createSizedBoxApp(const InicioTab(), size));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('ENCONTRAR PUNTO CERCANO'), findsOneWidget);
          expect(find.text('VER MAPA COMPLETO'), findsOneWidget);
        },
      );

      testWidgets(
        'PointsTab renders cleanly at ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final provider = AppStateProvider();
          await provider.loadCatalog();

          await tester.pumpWidget(
            createSizedBoxApp(
              const PointsTab(),
              size,
              customProvider: provider,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.text('Buscar distrito, parque o punto...'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'MoreTab renders cleanly at ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(createSizedBoxApp(const MoreTab(), size));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Preparación de Agua'), findsOneWidget);
        },
      );

      testWidgets(
        'MainScreen renders full chrome at ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(createSizedBoxApp(const MainScreen(), size));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('AguaCION'), findsOneWidget);
          expect(find.text('Inicio'), findsOneWidget);
          expect(find.text('Mapa'), findsOneWidget);
          expect(find.text('Puntos'), findsOneWidget);
          expect(find.text('Más'), findsOneWidget);
        },
      );
    }
  });
}
