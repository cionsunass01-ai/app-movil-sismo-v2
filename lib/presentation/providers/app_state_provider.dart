import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/water_point.dart';
import '../../data/models/sector_data.dart';
import '../../data/models/citizen_report.dart';
import '../../data/models/user_location.dart';
import '../../data/repositories/water_repository.dart';
import '../../core/services/audio_haptic_service.dart';
import '../../core/services/location_service.dart';

enum AppTab {
  puntos,
  mapa,
  sector,
  agua,
  reportar,
}

class AppStateProvider extends ChangeNotifier {
  final WaterRepository _repository = WaterRepository();

  bool _isEmergency = false;
  bool _isOnline = true;
  bool _isLiveGps = false;
  AppTab _activeTab = AppTab.puntos;
  WaterPoint? _selectedPoint;
  String? _notificationMessage;
  Timer? _notificationTimer;

  late UserLocation _userLocation;
  List<CitizenReport> _queuedReports = [];

  AppStateProvider() {
    _userLocation = _repository.getPredefinedLocations().first;
    _init();
  }

  // --- Getters ---
  bool get isEmergency => _isEmergency;
  bool get isOnline => _isOnline;
  bool get isLiveGps => _isLiveGps;
  AppTab get activeTab => _activeTab;
  WaterPoint? get selectedPoint => _selectedPoint;
  String? get notificationMessage => _notificationMessage;
  UserLocation get userLocation => _userLocation;
  List<CitizenReport> get queuedReports => _queuedReports;
  List<SectorData> get sectors => _repository.getSectors();
  List<UserLocation> get predefinedLocations => _repository.getPredefinedLocations();

  List<WaterPoint> get points => _repository.getPoints(_userLocation);

  int get activePointsCount =>
      points.where((p) => _isEmergency ? p.estE == EmergencyStatus.ok : true).length;

  SectorData get currentSectorData {
    return sectors.firstWhere(
      (s) => s.n == _userLocation.sector,
      orElse: () => sectors.first,
    );
  }

  WaterPoint? get nearestPoint => points.isNotEmpty ? points.first : null;

  // --- Initialization ---
  Future<void> _init() async {
    _queuedReports = await _repository.loadQueuedReports();
    notifyListeners();
  }

  // --- Notifications ---
  void showNotification(String msg) {
    _notificationMessage = msg;
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(milliseconds: 4500), () {
      _notificationMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void clearNotification() {
    _notificationMessage = null;
    _notificationTimer?.cancel();
    notifyListeners();
  }

  // --- Navigation & Point Selection ---
  void setActiveTab(AppTab tab) {
    _activeTab = tab;
    AudioHapticService.triggerClick();
    notifyListeners();
  }

  void selectPoint(WaterPoint? point) {
    _selectedPoint = point;
    AudioHapticService.triggerClick();
    notifyListeners();
  }

  // --- State Toggles ---
  void toggleEmergency() {
    _isEmergency = !_isEmergency;
    AudioHapticService.triggerEmergencyAlert();
    showNotification(
      _isEmergency
          ? '⚠ Alerta sísmica activada (≥ 8.5 Mw): racionamiento y puntos prioritarios activos.'
          : '✓ Modo regular restablecido: horarios habituales de suministro.',
    );
    notifyListeners();
  }

  Future<void> toggleOnline() async {
    _isOnline = !_isOnline;
    AudioHapticService.triggerClick();

    if (_isOnline) {
      if (_queuedReports.isNotEmpty) {
        final int count = _queuedReports.length;
        await _repository.clearQueuedReports();
        _queuedReports = [];
        showNotification(
          '✓ Conexión recuperada: $count ${count > 1 ? 'reportes sincronizados' : 'reporte sincronizado'} con COE EPS.',
        );
      } else {
        showNotification('✓ Conexión en línea restablecida');
      }
    } else {
      showNotification('📵 Modo 100% Offline: operando con GPS y cartografía local guardada');
    }
    notifyListeners();
  }

  // --- Location Management ---
  void setUserLocation(UserLocation location) {
    _userLocation = location;
    _isLiveGps = false;
    AudioHapticService.triggerClick();
    showNotification('📍 Ubicación simulada cambiada a: ${location.nombre}');
    notifyListeners();
  }

  Future<void> requestLiveGps() async {
    final liveLoc = await LocationService.getCurrentLocation();
    if (liveLoc != null) {
      _userLocation = liveLoc;
      _isLiveGps = true;
      AudioHapticService.triggerSuccess();
      showNotification('📍 GPS nativo activado con éxito');
    } else {
      AudioHapticService.triggerWarning();
      showNotification('⚠ No se pudo obtener señal GPS satelital directa');
    }
    notifyListeners();
  }

  // --- Reporting System ---
  Future<void> submitReport({
    required String puntoId,
    required String puntoNombre,
    required String tipoProblema,
    required String comentario,
    required String sector,
  }) async {
    final now = DateTime.now();
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final report = CitizenReport(
      id: 'REP-${now.millisecondsSinceEpoch}',
      puntoId: puntoId,
      puntoNombre: puntoNombre,
      tipoProblema: tipoProblema,
      comentario: comentario,
      timestamp: timeStr,
      offline: !_isOnline,
      sector: sector,
    );

    if (_isOnline) {
      AudioHapticService.triggerSuccess();
      showNotification('✓ Reporte transmitido de inmediato a SUNASS y COE EPS');
    } else {
      await _repository.saveQueuedReport(report);
      _queuedReports.insert(0, report);
      AudioHapticService.triggerSuccess();
      showNotification('✓ Sin señal: reporte guardado en memoria local. Se enviará al volver la red.');
    }
    notifyListeners();
  }

  Future<void> syncQueuedReports() async {
    if (_queuedReports.isNotEmpty) {
      final count = _queuedReports.length;
      await _repository.clearQueuedReports();
      _queuedReports = [];
      AudioHapticService.triggerSuccess();
      showNotification('✓ $count reportes sincronizados exitosamente con la central');
      notifyListeners();
    }
  }

  // --- Scenario Testing Actions ---
  void simulateCisternaArrival() {
    _repository.updatePointStatus(
      pointId: 'MOQ-PE-002',
      status: EmergencyStatus.ok,
      statusText: 'Con agua ahora (Cisterna 02 descargando)',
    );
    AudioHapticService.triggerEmergencyAlert();
    showNotification('🚚 Cisterna 02 llegó a Parque del Maestro: estado CON AGUA');
    notifyListeners();
  }

  void simulateOutagePoint() {
    _repository.updatePointStatus(
      pointId: 'MOQ-PE-004',
      status: EmergencyStatus.bad,
      statusText: 'Presión cero: corte temporal por rotura',
    );
    AudioHapticService.triggerEmergencyAlert();
    showNotification('⚠ Falla simulada en Parque La Alameda: presión en cero');
    notifyListeners();
  }

  Future<void> generateTestReport() async {
    final allPoints = points;
    final randomPoint = (allPoints..shuffle()).first;
    final now = DateTime.now();
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final testReport = CitizenReport(
      id: 'TEST-${now.millisecondsSinceEpoch.toString().substring(8)}',
      puntoId: randomPoint.id,
      puntoNombre: randomPoint.n,
      tipoProblema: 'Cola extensa sin resguardo policial',
      comentario: 'Más de 80 vecinos esperando con baldes, reportado desde la app offline.',
      timestamp: timeStr,
      offline: !_isOnline,
      sector: randomPoint.sector,
    );

    if (!_isOnline) {
      await _repository.saveQueuedReport(testReport);
    }
    _queuedReports.insert(0, testReport);
    AudioHapticService.triggerClick();
    showNotification('✓ Reporte de prueba generado y almacenado en cola');
    notifyListeners();
  }

  Future<void> resetAll() async {
    _repository.resetPoints();
    await _repository.clearQueuedReports();
    _queuedReports = [];
    _isEmergency = false;
    _isOnline = true;
    _isLiveGps = false;
    _userLocation = _repository.getPredefinedLocations().first;
    _selectedPoint = null;
    _activeTab = AppTab.puntos;
    AudioHapticService.triggerClick();
    showNotification('✓ Aplicación restablecida a valores iniciales');
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
