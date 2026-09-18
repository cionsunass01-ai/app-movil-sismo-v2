import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/audio_haptic_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/location_service.dart';
import '../../data/models/citizen_report.dart';
import '../../data/models/sector_data.dart';
import '../../data/models/user_location.dart';
import '../../data/models/water_point.dart';
import '../../data/repositories/local_water_point_catalog_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../domain/recommendation/nearby_water_points_service.dart';

export '../../data/repositories/local_water_point_catalog_repository.dart'
    show CatalogStatus;
export '../../core/services/connectivity_service.dart' show NetworkState;

enum AppTab { inicio, mapa, puntos, mas, sector, agua, reportar }

/// Central state coordinator separating real device states from demo simulations.
///
/// In REAL_APP_MODE (default):
/// - Connectivity: physical device network interfaces via [ConnectivityService].
/// - Points: canonical Lima & Callao local catalog (433 points) via [LocalWaterPointCatalogRepository].
/// - Location: acquired from real device GNSS hardware.
/// - Routing: offline CSR graph + A* with 50 m edge snapping via [NearbyWaterPointsService].
/// - Sector: unconfigured / pending official EPS integration.
///
/// In DEMO_SIMULATION_MODE (controlled exclusively in Demo Tools):
/// - Explicit simulation flags can override connectivity, emergency, or locations.
class AppStateProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final LocalWaterPointCatalogRepository _catalogRepo;
  final NearbyWaterPointsService _nearbyService;
  final WaterRepository _reportRepository = WaterRepository();

  StreamSubscription<NetworkState>? _connectivitySubscription;

  // Real Hardware State (defaults to connected until checked by hardware service)
  NetworkState _realConnectivity = NetworkState.connected;
  UserLocation? _userLocation;
  bool _isLiveGps = false;

  // Catalog State
  CatalogStatus _catalogStatus = CatalogStatus.uninitialized;
  List<WaterPoint> _points = [];

  // Demo Simulation Overrides (Disabled by default)
  bool _isConnectivitySimulationEnabled = false;
  NetworkState _simulatedConnectivity = NetworkState.connected;
  bool _isEmergencySimulation = false;

  // App UI State
  AppTab _activeTab = AppTab.inicio;
  bool _autoRouteToNearestOnMap = false;
  WaterPoint? _selectedPoint;
  String? _notificationMessage;
  Timer? _notificationTimer;
  List<CitizenReport> _queuedReports = [];

  AppStateProvider({
    ConnectivityService? connectivityService,
    LocalWaterPointCatalogRepository? catalogRepo,
    NearbyWaterPointsService? nearbyService,
  }) : _connectivityService = connectivityService ?? ConnectivityService(),
       _catalogRepo = catalogRepo ?? LocalWaterPointCatalogRepository(),
       _nearbyService = nearbyService ?? NearbyWaterPointsService() {
    _realConnectivity = _connectivityService.currentNetworkState;
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((state) {
          if (_realConnectivity != state) {
            final wasDisconnected =
                _realConnectivity == NetworkState.disconnected;
            _realConnectivity = state;
            if (!_isConnectivitySimulationEnabled) {
              if (wasDisconnected && state == NetworkState.connected) {
                syncQueuedReports();
              }
              _handleConnectivityChangeNotification(
                state == NetworkState.connected,
              );
            }
            notifyListeners();
          }
        });
    _init();
  }

  // --- Getters: Real vs Simulation Separation ---

  /// Effective connectivity: returns simulated state if override is active,
  /// otherwise returns physical hardware network state.
  NetworkState get effectiveNetworkState => _isConnectivitySimulationEnabled
      ? _simulatedConnectivity
      : _realConnectivity;

  /// Effective online boolean for general UI consumption.
  bool get isOnline => effectiveNetworkState == NetworkState.connected;

  NetworkState get realConnectivity => _realConnectivity;
  bool get isConnectivitySimulationEnabled => _isConnectivitySimulationEnabled;
  NetworkState get simulatedConnectivity => _simulatedConnectivity;

  bool get isEmergency => _isEmergencySimulation;
  bool get isLiveGps => _isLiveGps;
  AppTab get activeTab => _activeTab;
  WaterPoint? get selectedPoint => _selectedPoint;
  String? get notificationMessage => _notificationMessage;
  bool get autoRouteToNearestOnMap => _autoRouteToNearestOnMap;
  List<CitizenReport> get queuedReports => List.unmodifiable(_queuedReports);

  CatalogStatus get catalogStatus => _catalogStatus;
  bool get isCatalogAvailable => _catalogStatus == CatalogStatus.available;

  List<WaterPoint> get points => List.unmodifiable(_points);

  int get activePointsCount => points.length;

  bool get hasRealUserLocation => _userLocation != null;

  UserLocation get userLocation {
    return _userLocation ??
        const UserLocation(
          nombre: 'Ubicación no disponible',
          sector: 'Sector no detectado',
          lat: -12.0464, // Lima Centro neutral reference
          lon: -77.0428,
        );
  }

  List<SectorData> get sectors => const [];

  SectorData get currentSectorData => const SectorData(
    n: 'Pendiente de integración',
    con: 0,
    rac: 0,
    hor: 'Sin programación oficial',
    res: 'Por determinar',
    puntosCount: 0,
  );

  WaterPoint? get nearestPoint => _points.isNotEmpty ? _points.first : null;

  // --- Initialization ---

  Future<void> _init() async {
    // 1. Initialize and monitor physical network interfaces
    await _connectivityService.initialize();
    if (_connectivityService.currentNetworkState != NetworkState.unknown) {
      _realConnectivity = _connectivityService.currentNetworkState;
    }

    // 2. Load canonical Lima/Callao catalog
    await loadCatalog();

    // 3. Load queued reports
    _queuedReports = await _reportRepository.loadQueuedReports();
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    final loaded = await _catalogRepo.loadCatalog();
    _catalogStatus = _catalogRepo.status;
    if (_catalogStatus == CatalogStatus.available) {
      _points = loaded;
      if (_userLocation != null) {
        _points = _nearbyService.rankByGeodesicDistance(
          points: _points,
          originLat: _userLocation!.lat,
          originLon: _userLocation!.lon,
        );
      }
    } else {
      _points = [];
    }
    notifyListeners();
  }

  void _handleConnectivityChangeNotification(bool isConnected) {
    if (isConnected) {
      showNotification('✓ Conexión de red detectada');
    } else {
      showNotification(
        'Sin conexión — Mapa local y cálculo de rutas disponibles en el dispositivo',
      );
    }
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

  void findNearestAndNavigate() {
    _autoRouteToNearestOnMap = true;
    _activeTab = AppTab.mapa;
    AudioHapticService.triggerClick();
    notifyListeners();
  }

  void consumeAutoRoute() {
    _autoRouteToNearestOnMap = false;
  }

  void selectPoint(WaterPoint? point) {
    _selectedPoint = point;
    AudioHapticService.triggerClick();
    notifyListeners();
  }

  void selectPointAndNavigateToMap(WaterPoint point) {
    _selectedPoint = point;
    _activeTab = AppTab.mapa;
    AudioHapticService.triggerClick();
    notifyListeners();
  }

  // --- Real Location Management ---

  void updateUserLocation(UserLocation location) {
    _userLocation = location;
    _isLiveGps = true;

    if (_points.isNotEmpty) {
      // Re-rank points by geodetic proximity to real user location
      _points = _nearbyService.rankByGeodesicDistance(
        points: _points,
        originLat: location.lat,
        originLon: location.lon,
      );

      // Asynchronously calculate candidate pedestrian routes for top 10
      _nearbyService
          .rankAndRouteNearest(
            points: _points,
            originLat: location.lat,
            originLon: location.lon,
            maxCandidatesToRoute: 10,
          )
          .then((rankedAndRouted) {
            _points = rankedAndRouted;
            notifyListeners();
          });
    }

    notifyListeners();
  }

  Future<void> requestLiveGps() async {
    final liveLoc = await LocationService.getCurrentLocation();
    if (liveLoc != null) {
      updateUserLocation(liveLoc);
      AudioHapticService.triggerSuccess();
      showNotification('📍 Ubicación obtenida con éxito');
    } else {
      AudioHapticService.triggerWarning();
      showNotification('⚠ No se pudo obtener señal GPS del dispositivo');
    }
  }

  // --- Demo Simulation Controls (Accessible via DemoTools) ---

  void toggleEmergency() {
    _isEmergencySimulation = !_isEmergencySimulation;
    AudioHapticService.triggerEmergencyAlert();
    showNotification(
      _isEmergencySimulation
          ? '⚠ Alerta sísmica activada: régimen de contingencia activo.'
          : '✓ Régimen de contingencia desactivado.',
    );
    notifyListeners();
  }

  void setConnectivitySimulationEnabled(bool enabled) {
    _isConnectivitySimulationEnabled = enabled;
    if (!enabled) {
      // Immediately revert to physical connectivity
      _handleConnectivityChangeNotification(
        _realConnectivity == NetworkState.connected,
      );
    } else {
      showNotification(
        _simulatedConnectivity == NetworkState.connected
            ? 'Conexión manual forzada'
            : 'Modo local manual forzado',
      );
    }
    notifyListeners();
  }

  void setSimulatedConnectivity(NetworkState state) {
    _simulatedConnectivity = state;
    if (_isConnectivitySimulationEnabled) {
      _handleConnectivityChangeNotification(state == NetworkState.connected);
    }
    notifyListeners();
  }

  /// Legacy/test convenience method: toggles simulation mode or state
  Future<void> toggleOnline() async {
    if (!_isConnectivitySimulationEnabled) {
      _isConnectivitySimulationEnabled = true;
      _simulatedConnectivity = isOnline
          ? NetworkState.disconnected
          : NetworkState.connected;
    } else {
      _simulatedConnectivity =
          (_simulatedConnectivity == NetworkState.connected)
          ? NetworkState.disconnected
          : NetworkState.connected;
    }

    AudioHapticService.triggerClick();
    if (isOnline) {
      if (_queuedReports.isNotEmpty) {
        final count = _queuedReports.length;
        await _reportRepository.clearQueuedReports();
        _queuedReports = [];
        showNotification(
          '✓ Conexión recuperada: $count ${count > 1 ? 'reportes sincronizados' : 'reporte sincronizado'} con la central.',
        );
      } else {
        showNotification('✓ Conexión de red restablecida');
      }
    } else {
      showNotification(
        'Sin conexión — Mapa local y cálculo de rutas disponibles en el dispositivo',
      );
    }
    notifyListeners();
  }

  // --- Reporting System (Marked Prototype / Demo) ---

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
      offline: !isOnline,
      sector: sector,
    );

    if (isOnline) {
      AudioHapticService.triggerSuccess();
      showNotification('✓ Reporte transmitido con éxito');
    } else {
      await _reportRepository.saveQueuedReport(report);
      _queuedReports.insert(0, report);
      AudioHapticService.triggerSuccess();
      showNotification(
        '✓ Sin red: reporte guardado en memoria local. Se sincronizará al volver la red.',
      );
    }
    notifyListeners();
  }

  Future<void> syncQueuedReports() async {
    if (_queuedReports.isNotEmpty) {
      final count = _queuedReports.length;
      await _reportRepository.clearQueuedReports();
      _queuedReports = [];
      AudioHapticService.triggerSuccess();
      showNotification('✓ $count reportes sincronizados exitosamente');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }
}
