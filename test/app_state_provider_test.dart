import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aguacion_app/presentation/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStateProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state is correct and loads canonical points', () async {
      final provider = AppStateProvider();
      await provider.loadCatalog();
      expect(provider.isEmergency, false);
      expect(provider.isOnline, true);
      expect(provider.activeTab, AppTab.inicio);
      expect(provider.points.isNotEmpty, true);
      expect(provider.currentSectorData.n, 'Pendiente de integración');
    });

    test('toggleEmergency flips isEmergency state', () {
      final provider = AppStateProvider();
      provider.toggleEmergency();
      expect(provider.isEmergency, true);
      expect(provider.notificationMessage, contains('Alerta sísmica activada'));
    });

    test('submitReport queues report when offline', () async {
      final provider = AppStateProvider();
      await provider.toggleOnline(); // switch to offline
      expect(provider.isOnline, false);

      await provider.submitReport(
        puntoId: 'PTO-001',
        puntoNombre: 'Punto de Prueba',
        tipoProblema: 'Sin agua',
        comentario: 'Test comentario',
        sector: 'Lima',
      );

      expect(provider.queuedReports.length, 1);
      expect(provider.queuedReports.first.puntoNombre, 'Punto de Prueba');

      // Now return online and sync
      await provider.toggleOnline();
      expect(provider.isOnline, true);
      expect(provider.queuedReports.isEmpty, true);
    });
  });
}
