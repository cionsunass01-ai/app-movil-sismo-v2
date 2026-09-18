// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maplibre_gl/maplibre_gl.dart' hide UserLocation;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../domain/location/models/gnss_state.dart';
import '../../../domain/routing/models/route_result.dart';
import '../../../data/repositories/local_location_repository.dart';
import '../../../data/repositories/local_routing_repository.dart';
import '../../../data/models/user_location.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/location_permission_modal.dart';
import 'widgets/water_point_map_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _engine = LocalRoutingRepository.instance;
  final _locationService = LocalLocationRepository();

  // Neutral fallback: Centro de Lima (Plaza Mayor / Metropolitano)
  static const LatLng kNeutralLimaCenter = LatLng(-12.0464, -77.0428);

  bool _isLoading = true;
  String _loadingMessage = 'Preparando mapa y red peatonal offline...';
  bool _isLocating = false;
  bool _hasInitialCenteredOnUser = false;

  MapLibreMapController? _mapController;
  GnssPosition? _currentPosition;

  Map<String, dynamic>? _selectedPoint;
  RouteResult? _currentRoute;
  final Set<int> _blockedEdgeIds = {};

  @override
  void initState() {
    super.initState();
    _initEngineAndLocation();
  }

  Future<void> _initEngineAndLocation() async {
    try {
      await _engine.ensureInitialized(
        onProgress: (msg) {
          if (mounted) setState(() => _loadingMessage = msg);
        },
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Error al cargar mapa offline: $e';
        });
      }
    }

    // Auto-acquire user location on entry without blocking initial map display
    _autoAcquireLocation();
  }

  Future<void> _autoAcquireLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    final pos = await _locationService.acquirePosition(
      timeoutSeconds: 5,
      requestIfNotGranted: false,
    );
    if (!mounted) return;

    final bool hasValidPosition =
        pos.state == LocationState.current ||
        pos.state == LocationState.lastKnown;

    setState(() {
      _isLocating = false;
      if (hasValidPosition) {
        _currentPosition = pos;
      } else {
        _currentPosition = null;
      }
    });

    if (hasValidPosition) {
      // Update global app state with real location
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.updateUserLocation(
        UserLocation(
          nombre: 'Mi Ubicación',
          sector: 'Detectado por GPS',
          lat: pos.latitude,
          lon: pos.longitude,
        ),
      );

      await _renderUserLocationLayer();

      // Center camera on user once automatically
      if (!_hasInitialCenteredOnUser && _mapController != null) {
        _hasInitialCenteredOnUser = true;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15.0),
        );
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    await _renderWaterPointsLayer();
    if (_currentPosition != null) {
      await _renderUserLocationLayer();
    }

    if (!mounted) return;

    // Check if auto-centering was pending controller readiness
    if (!_hasInitialCenteredOnUser &&
        _currentPosition != null &&
        _mapController != null) {
      _hasInitialCenteredOnUser = true;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.autoRouteToNearestOnMap) {
      appState.consumeAutoRoute();
      _calculateNearestRoute();
    } else if (appState.selectedPoint != null) {
      _selectPointById(appState.selectedPoint!.id);
    }
  }

  Future<void> _renderWaterPointsLayer() async {
    if (_mapController == null || _engine.waterPoints.isEmpty) return;

    final features = _engine.waterPoints.map((p) {
      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [
            (p['longitude'] as num).toDouble(),
            (p['latitude'] as num).toDouble(),
          ],
        },
        'properties': {
          'id': p['water_point_id'] ?? '',
          'district': p['district'] ?? '',
          'location': p['location_description'] ?? '',
        },
      };
    }).toList();

    try {
      await _mapController!.addGeoJsonSource('sunass_water_points', {
        'type': 'FeatureCollection',
        'features': features,
      });
      await _mapController!.addCircleLayer(
        'sunass_water_points',
        'water_points_circles',
        const CircleLayerProperties(
          circleRadius: 6.0,
          circleColor: '#00A3E0', // Sunass Cyan
          circleStrokeWidth: 2.0,
          circleStrokeColor: '#ffffff',
        ),
      );
    } catch (_) {}
  }

  Future<void> _renderUserLocationLayer() async {
    if (_mapController == null || _currentPosition == null) return;
    try {
      // If source already exists, update data
      await _mapController!.addGeoJsonSource('user_location_source', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                _currentPosition!.longitude,
                _currentPosition!.latitude,
              ],
            },
            'properties': {'title': 'Mi Ubicación'},
          },
        ],
      });

      await _mapController!.addCircleLayer(
        'user_location_source',
        'user_location_halo',
        const CircleLayerProperties(
          circleRadius: 14.0,
          circleColor: '#38bdf8',
          circleOpacity: 0.40,
          circleStrokeWidth: 1.5,
          circleStrokeColor: '#0284c7',
        ),
      );

      await _mapController!.addCircleLayer(
        'user_location_source',
        'user_location_dot',
        const CircleLayerProperties(
          circleRadius: 7.5,
          circleColor: '#ef4444',
          circleStrokeWidth: 2.5,
          circleStrokeColor: '#ffffff',
        ),
      );
    } catch (_) {
      // If layers already exist, update coordinates
      _updateUserLocationMarker();
    }
  }

  void _updateUserLocationMarker() {
    if (_mapController == null || _currentPosition == null) return;
    try {
      _mapController!.setGeoJsonSource('user_location_source', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                _currentPosition!.longitude,
                _currentPosition!.latitude,
              ],
            },
            'properties': {'title': 'Mi Ubicación'},
          },
        ],
      });
    } catch (_) {}
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLocating = true);
    final pos = await _locationService.acquirePosition(timeoutSeconds: 8);
    if (!mounted) return;

    final bool hasValidPosition =
        pos.state == LocationState.current ||
        pos.state == LocationState.lastKnown;

    setState(() {
      _isLocating = false;
      if (hasValidPosition) {
        _currentPosition = pos;
      }
    });

    if (hasValidPosition) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.updateUserLocation(
        UserLocation(
          nombre: 'Mi Ubicación',
          sector: 'Detectado por GPS',
          lat: pos.latitude,
          lon: pos.longitude,
        ),
      );

      await _renderUserLocationLayer();
      _centerOnUser();
    } else {
      final msg = pos.state == LocationState.permissionDenied
          ? 'Permiso de ubicación denegado en el navegador. Haz clic en el candado 🔒 junto a la URL y selecciona "Permitir ubicación".'
          : (pos.message.isNotEmpty
              ? pos.message
              : 'No se pudo obtener la ubicación GPS.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.slate800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _requestLocationWithPrimer() {
    if (_currentPosition != null) {
      _centerOnUser();
      return;
    }
    LocationPermissionModal.show(
      context,
      onAccept: _refreshLocation,
    );
  }

  void _centerOnUser() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  Future<void> _calculateNearestRoute() async {
    // If no position yet, attempt quick acquisition
    if (_currentPosition == null) {
      await _refreshLocation();
    }

    if (!mounted) return;

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Active el GPS para calcular la ruta al punto más cercano.',
          ),
        ),
      );
      return;
    }

    final search = _engine.searchNearest(
      originLat: _currentPosition!.latitude,
      originLon: _currentPosition!.longitude,
      snapThresholdMeters: 50.0,
      blockedEdgeIds: _blockedEdgeIds,
    );

    if (!mounted) return;

    if (search != null && search.winnerPoint != null) {
      setState(() {
        _selectedPoint = search.winnerPoint;
        _currentRoute = search.winnerRoute;
      });
      _drawRouteOnMap();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró una vía peatonal transitable a menos de 50 m para conectar con un punto.',
          ),
        ),
      );
    }
  }

  void _selectPointById(String id) {
    final match = _engine.waterPoints.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p?['water_point_id'] == id,
      orElse: () => null,
    );
    if (match != null) {
      _selectPoint(match);
    }
  }

  void _selectPoint(Map<String, dynamic> point) {
    setState(() {
      _selectedPoint = point;
      _currentRoute = null;
    });

    final lat = (point['latitude'] as num).toDouble();
    final lon = (point['longitude'] as num).toDouble();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lon), 15.0),
    );
  }

  void _calculateRouteToSelected() {
    if (_selectedPoint == null) return;
    if (_currentPosition == null) {
      LocationPermissionModal.show(
        context,
        onAccept: () async {
          await _refreshLocation();
          if (_currentPosition != null) {
            _calculateRouteToSelected();
          }
        },
      );
      return;
    }

    final destLat = (_selectedPoint!['latitude'] as num).toDouble();
    final destLon = (_selectedPoint!['longitude'] as num).toDouble();

    final route = _engine.routeToPoint(
      originLat: _currentPosition!.latitude,
      originLon: _currentPosition!.longitude,
      destinationLat: destLat,
      destinationLon: destLon,
      snapThresholdMeters: 50.0,
      blockedEdgeIds: _blockedEdgeIds,
    );

    if (route != null && route.isSuccess) {
      setState(() => _currentRoute = route);
      _drawRouteOnMap();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin ruta peatonal disponible a menos de 50 m para este punto.',
          ),
        ),
      );
    }
  }

  Future<void> _drawRouteOnMap() async {
    if (_mapController == null ||
        _currentRoute == null ||
        !_currentRoute!.isSuccess) {
      return;
    }

    final latLngs = _currentRoute!.polylineCoords
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    try {
      await _mapController!.clearLines();
      if (latLngs.length >= 2) {
        // Casing line (white background for contrast)
        await _mapController!.addLine(
          LineOptions(
            geometry: latLngs,
            lineColor: '#ffffff',
            lineWidth: 8.5,
            lineOpacity: 0.95,
            lineJoin: 'round',
          ),
        );
        // Core green walking route line
        await _mapController!.addLine(
          LineOptions(
            geometry: latLngs,
            lineColor: '#059669', // Emerald Green
            lineWidth: 5.0,
            lineOpacity: 1.0,
            lineJoin: 'round',
          ),
        );
      }
    } catch (_) {}

    _fitRouteCameraBounds();
  }

  void _fitRouteCameraBounds() {
    if (_mapController == null ||
        _selectedPoint == null ||
        _currentPosition == null) {
      return;
    }

    final p1Lat = _currentPosition!.latitude;
    final p1Lon = _currentPosition!.longitude;
    final p2Lat = (_selectedPoint!['latitude'] as num).toDouble();
    final p2Lon = (_selectedPoint!['longitude'] as num).toDouble();

    double minLat = math.min(p1Lat, p2Lat);
    double maxLat = math.max(p1Lat, p2Lat);
    double minLon = math.min(p1Lon, p2Lon);
    double maxLon = math.max(p1Lon, p2Lon);

    if (_currentRoute != null && _currentRoute!.polylineCoords.isNotEmpty) {
      for (final coord in _currentRoute!.polylineCoords) {
        final lon = coord[0];
        final lat = coord[1];
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLon = math.min(minLon, lon);
        maxLon = math.max(maxLon, lon);
      }
    }

    final latDelta = (maxLat - minLat).abs();
    final lonDelta = (maxLon - minLon).abs();

    final effectiveMinLat = latDelta < 0.003
        ? minLat - 0.002
        : minLat - (latDelta * 0.15);
    final effectiveMaxLat = latDelta < 0.003
        ? maxLat + 0.002
        : maxLat + (latDelta * 0.15);
    final effectiveMinLon = lonDelta < 0.003
        ? minLon - 0.002
        : minLon - (lonDelta * 0.15);
    final effectiveMaxLon = lonDelta < 0.003
        ? maxLon + 0.002
        : maxLon + (lonDelta * 0.15);

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(effectiveMinLat, effectiveMinLon),
            northeast: LatLng(effectiveMaxLat, effectiveMaxLon),
          ),
          left: 36,
          top: 60,
          right: 36,
          bottom: 220,
        ),
      );
    } catch (_) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2),
          14.0,
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _selectedPoint = null;
    });
    _mapController?.clearLines();
  }

  void _show48hDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(LucideIcons.clockAlert, color: Color(0xFF0284C7), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Actualización Post-Desastre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Red preventiva oficial de abastecimiento',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              'Este mapa contiene los 433 puntos de distribución oficial planificados para contingencias en Lima y Callao.\n\nTras un sismo o catástrofe de gran magnitud, la habilitación operativa en campo (llegada de camiones cisterna, apertura de piletas y surtidores) es verificada y consolidada en terreno por los equipos técnicos en un plazo máximo de 48 horas post-evento.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate700,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunassNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _onMapClick(math.Point<double> point, LatLng latLng) {
    if (_engine.waterPoints.isEmpty) return;

    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    for (final p in _engine.waterPoints) {
      final pLat = (p['latitude'] as num).toDouble();
      final pLon = (p['longitude'] as num).toDouble();
      final dist = GeoUtils.calculateDistanceMeters(
        latLng.latitude,
        latLng.longitude,
        pLat,
        pLon,
      ).toDouble();
      if (dist < minDistance) {
        minDistance = dist;
        closest = p;
      }
    }

    if (closest != null && minDistance <= 1500) {
      _selectPoint(closest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    if (state.autoRouteToNearestOnMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.consumeAutoRoute();
        _calculateNearestRoute();
      });
    }

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.sunassBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicializando mapa vectorial local y grafo de Lima Metropolitana',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
              ),
            ],
          ),
        ),
      );
    }

    if (_engine.styleString == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                size: 44,
                color: AppColors.primaryRed,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el mapa offline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                kIsWeb
                    ? 'Para usar el mapa sin internet, se requiere una primera descarga de 10 MB con conexión. Una vez guardado en la memoria de tu celular, estará disponible 100% offline.'
                    : 'Compruebe que el archivo PMTiles esté disponible en el almacenamiento local.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initEngineAndLocation();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // 1. MapLibre Map View centered on neutral Lima Centro fallback
        MapLibreMap(
          styleString: _engine.styleString!,
          initialCameraPosition: const CameraPosition(
            target: kNeutralLimaCenter,
            zoom: 11.5,
          ),
          minMaxZoomPreference: const MinMaxZoomPreference(9.0, 18.0),
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onMapClick: _onMapClick,
          myLocationEnabled: false,
          trackCameraPosition: true,
          compassEnabled: true,
        ),

        // 2. Top Location Status Banner (when locating or location unavailable)
        if (_isLocating)
          Positioned(
            top: 14,
            left: 14,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.sunassBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obteniendo tu ubicación...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_currentPosition == null)
          Positioned(
            top: 14,
            left: 14,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.mapPinOff,
                    size: 14,
                    color: AppColors.slate500,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ubicación no disponible',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _requestLocationWithPrimer,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Activar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sunassBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 2b. 48h Post-Disaster Notice Banner
        Positioned(
          top: (_isLocating || _currentPosition == null) ? 56 : 14,
          left: 14,
          right: 80,
          child: InkWell(
            onTap: _show48hDisclaimerDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.clockAlert,
                    size: 13,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Puntos sujetos a confirmación operativa (máx. 48 h)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    LucideIcons.info,
                    size: 12,
                    color: AppColors.slate400,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Floating Action Controls (GPS & Demo Tools)
        Positioned(
          top: 14,
          right: 14,
          child: Column(
            children: [
              // GPS Button
              FloatingActionButton.small(
                heroTag: 'map_gps_btn',
                onPressed: _isLocating ? null : _requestLocationWithPrimer,
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.sunassNavy,
                elevation: 3,
                child: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.sunassBlue,
                          ),
                        ),
                      )
                    : const Icon(LucideIcons.locateFixed, size: 19),
              ),
            ],
          ),
        ),

        // 4. Bottom Card / Sheet (Point details & Route actions)
        if (_selectedPoint != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WaterPointMapSheet(
              pointData: _selectedPoint!,
              hasActiveRoute: _currentRoute != null && _currentRoute!.isSuccess,
              routeDistance: _currentRoute?.formattedDistance,
              routeDuration: _currentRoute?.formattedDuration,
              onCalculateRoute: _calculateRouteToSelected,
              onRecenter: _fitRouteCameraBounds,
              onClearRoute: _clearRoute,
              onClose: () => setState(() => _selectedPoint = null),
              isEmergency: state.isEmergency,
            ),
          ),
      ],
    );
  }
}
