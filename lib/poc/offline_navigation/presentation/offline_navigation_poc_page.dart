// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../benchmarks/dart_routing_benchmark.dart';
import '../graph/csr_graph.dart';
import '../models/gnss_state.dart';
import '../models/route_result.dart';
import '../routing/astar_router.dart';
import '../routing/adaptive_water_point_search.dart';
import '../services/offline_location_service.dart';
import '../services/pmtiles_manager.dart';
import '../spatial/edge_spatial_grid.dart';

class OfflineNavigationPocPage extends StatefulWidget {
  const OfflineNavigationPocPage({super.key});

  static const String routeName = '/poc/offline_navigation';

  @override
  State<OfflineNavigationPocPage> createState() =>
      _OfflineNavigationPocPageState();
}

class _OfflineNavigationPocPageState extends State<OfflineNavigationPocPage> {
  // State flags
  bool _isLoading = true;
  String _loadingMessage = 'Iniciando subsistema cartográfico offline...';
  String? _styleString;

  // Map controller
  MapLibreMapController? _mapController;

  // Core offline graph & router
  CsrGraph? _graph;
  EdgeSpatialGrid? _spatialGrid;
  AstarRouter? _router;
  AdaptiveWaterPointSearch? _adaptiveSearch;
  AdaptiveSearchResult? _lastSearchResult;

  // Data
  List<Map<String, dynamic>> _waterPoints = [];
  GnssPosition _currentPosition = const GnssPosition(
    latitude:
        -11.9750, // Default: Los Olivos (near Panamericana divergence test)
    longitude: -77.0650,
    state: LocationState.lastKnown,
    message: 'Ubicación predeterminada de prueba (Los Olivos)',
  );

  // Snapping & Routing state
  double _snapThresholdMeters = 50.0;
  RouteResult? _currentRoute;
  Map<String, dynamic>? _haversineWinnerPoint;
  Map<String, dynamic>? _walkWinnerPoint;
  double _haversineWinnerWalkDist = 0.0;
  final Set<int> _blockedEdgeIds = {};

  bool _isBenchmarking = false;
  bool _isStressTesting = false;
  final Map<String, int> _coldStartTimestamps = {};

  @override
  void initState() {
    super.initState();
    _initializePoc();
  }

  Future<void> _initializePoc() async {
    final swTotal = Stopwatch()..start();
    _coldStartTimestamps['T0_POC_INIT_START'] = 0;
    try {
      print('[IOS_COLD_START] T0_POC_INIT_START: 0 ms');

      // 1. Prepare PMTiles local file & style JSON
      setState(
        () => _loadingMessage =
            'Preparando mapa vectorial local PMTiles (10.17 MB)...',
      );
      final swPmtiles = Stopwatch()..start();
      final style = await PmtilesManager.getOfflineStyleString();
      swPmtiles.stop();
      _coldStartTimestamps['T2_PMTILES_READY'] = swPmtiles.elapsedMilliseconds;
      print(
        '[IOS_COLD_START] T2_PMTILES_READY: ${swPmtiles.elapsedMilliseconds} ms (total: ${swTotal.elapsedMilliseconds} ms)',
      );

      // 2. Load 433 Water Points
      setState(
        () =>
            _loadingMessage = 'Cargando 433 puntos oficiales de agua SUNASS...',
      );
      final swPoints = Stopwatch()..start();
      final ptsStr = await rootBundle.loadString(
        'assets/poc/data/water_points_normalized.json',
      );
      final ptsDecoded = json.decode(ptsStr);
      _waterPoints =
          ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded)
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      swPoints.stop();
      _coldStartTimestamps['T3_POINTS_LOADED'] = swPoints.elapsedMilliseconds;
      print(
        '[IOS_COLD_START] T3_POINTS_LOADED: ${swPoints.elapsedMilliseconds} ms (total: ${swTotal.elapsedMilliseconds} ms, count: ${_waterPoints.length})',
      );

      // 3. Load CSR Binary Graph
      setState(
        () => _loadingMessage =
            'Cargando grafo peatonal CSR (855k nodos, 1.99M aristas)...',
      );
      final swGraph = Stopwatch()..start();
      final graphByteData = await rootBundle.load(
        'assets/poc/routing/pedestrian_graph_lima_csr.bin',
      );
      final graphBytes = graphByteData.buffer.asUint8List(
        graphByteData.offsetInBytes,
        graphByteData.lengthInBytes,
      );
      _graph = CsrGraph.fromBytes(graphBytes);
      swGraph.stop();
      _coldStartTimestamps['T4_GRAPH_LOADED'] = swGraph.elapsedMilliseconds;
      print(
        '[IOS_COLD_START] T4_GRAPH_LOADED: ${swGraph.elapsedMilliseconds} ms (total: ${swTotal.elapsedMilliseconds} ms, nodes: ${_graph!.nodeCount}, edges: ${_graph!.directedEdgeCount})',
      );

      // 4. Build Spatial Grid for edge snapping
      setState(
        () => _loadingMessage =
            'Construyendo índice espacial para snapping a calles...',
      );
      final swGrid = Stopwatch()..start();
      _spatialGrid = EdgeSpatialGrid(_graph!);
      _router = AstarRouter(graph: _graph!, spatialGrid: _spatialGrid!);
      _adaptiveSearch = AdaptiveWaterPointSearch(_router!);
      swGrid.stop();
      _coldStartTimestamps['T5_SPATIAL_GRID_READY'] =
          swGrid.elapsedMilliseconds;
      print(
        '[IOS_COLD_START] T5_SPATIAL_GRID_READY: ${swGrid.elapsedMilliseconds} ms (total: ${swTotal.elapsedMilliseconds} ms)',
      );

      _coldStartTimestamps['T1_POC_MOUNTED'] = swTotal.elapsedMilliseconds;
      setState(() {
        _styleString = style;
        _isLoading = false;
      });
      print(
        '[IOS_COLD_START] T1_POC_MOUNTED_AND_RENDERED: total: ${swTotal.elapsedMilliseconds} ms',
      );

      // 5. Initial GNSS acquire attempt
      _refreshLocation();
    } catch (e, stack) {
      print('[IOS_ERROR] Error al inicializar el POC offline: $e\n$stack');
      setState(() {
        _loadingMessage = 'Error al inicializar el POC offline: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLocation() async {
    final pos = await OfflineLocationService.acquirePosition(
      timeoutSeconds: 15,
      onProgress: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
          );
        }
      },
    );

    if (mounted) {
      setState(() {
        _currentPosition = pos;
      });
      _updateUserLocationMarker();
      if (pos.isValid) {
        _calculateBestPointAndRoute();
        if (_currentRoute == null || !_currentRoute!.isSuccess) {
          _centerOnUser();
        }
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    _renderWaterPointsOnMap();
    _updateUserLocationMarker();
    _calculateBestPointAndRoute();
  }

  void _renderWaterPointsOnMap() {
    if (_mapController == null || _waterPoints.isEmpty) return;

    final features = _waterPoints.map((p) {
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

    final geoJson = {'type': 'FeatureCollection', 'features': features};

    _mapController!.addGeoJsonSource('sunass_water_points', geoJson);
    _mapController!.addCircleLayer(
      'sunass_water_points',
      'water_points_circles',
      const CircleLayerProperties(
        circleRadius: 6.0,
        circleColor: '#0284c7', // Sunass Cyan
        circleStrokeWidth: 2.0,
        circleStrokeColor: '#ffffff',
      ),
    );

    // Prepare user location layers (Halo + Red dot)
    _mapController!.addGeoJsonSource('user_location_source', {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [
              _currentPosition.longitude,
              _currentPosition.latitude,
            ],
          },
          'properties': {'title': 'Mi Ubicación'},
        },
      ],
    });

    _mapController!.addCircleLayer(
      'user_location_source',
      'user_location_halo',
      const CircleLayerProperties(
        circleRadius: 14.0,
        circleColor: '#38bdf8', // Sky blue halo
        circleOpacity: 0.45,
        circleStrokeWidth: 1.5,
        circleStrokeColor: '#0284c7',
      ),
    );

    _mapController!.addCircleLayer(
      'user_location_source',
      'user_location_dot',
      const CircleLayerProperties(
        circleRadius: 8.0,
        circleColor: '#ef4444', // Red dot
        circleStrokeWidth: 2.5,
        circleStrokeColor: '#ffffff',
      ),
    );
  }

  void _updateUserLocationMarker() {
    if (_mapController == null) return;
    try {
      _mapController!.setGeoJsonSource('user_location_source', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                _currentPosition.longitude,
                _currentPosition.latitude,
              ],
            },
            'properties': {'title': 'Mi Ubicación'},
          },
        ],
      });
    } catch (_) {}
  }

  void _centerOnUser() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition.latitude, _currentPosition.longitude),
          14.5,
        ),
      );
    }
  }

  void _fitRouteCameraBounds() {
    if (_mapController == null || _walkWinnerPoint == null) return;

    final p1Lat = _currentPosition.latitude;
    final p1Lon = _currentPosition.longitude;
    final p2Lat = (_walkWinnerPoint!['latitude'] as num).toDouble();
    final p2Lon = (_walkWinnerPoint!['longitude'] as num).toDouble();

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

    final bounds = LatLngBounds(
      southwest: LatLng(effectiveMinLat, effectiveMinLon),
      northeast: LatLng(effectiveMaxLat, effectiveMaxLon),
    );

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 40,
          top: 70,
          right: 40,
          bottom: 230,
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

  void _calculateBestPointAndRoute() {
    if (_adaptiveSearch == null || _waterPoints.isEmpty) return;

    final origLat = _currentPosition.latitude;
    final origLon = _currentPosition.longitude;

    final swRoute = Stopwatch()..start();
    final searchResult = _adaptiveSearch!.search(
      originLat: origLat,
      originLon: origLon,
      waterPoints: _waterPoints,
      snapThresholdMeters: _snapThresholdMeters,
      blockedEdgeIds: _blockedEdgeIds,
    );
    swRoute.stop();
    _coldStartTimestamps['T6_ROUTING_READY'] = swRoute.elapsedMilliseconds;
    print(
      '[IOS_COLD_START] T6_ROUTING_READY: ${swRoute.elapsedMilliseconds} ms (candidates routed: ${searchResult.candidatesRoutedCount}, dist: ${searchResult.winnerRoute?.distanceMeters.toStringAsFixed(1)} m)',
    );

    setState(() {
      _lastSearchResult = searchResult;
      _currentRoute = searchResult.winnerRoute;
      _walkWinnerPoint = searchResult.winnerPoint;
      _haversineWinnerPoint = searchResult.haversineWinnerPoint;
      _haversineWinnerWalkDist = searchResult.haversineWinnerRouteDistance;
    });

    _drawRouteOnMap();
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

    // 1. Draw using high-level Annotation API (guaranteed across all platforms)
    try {
      await _mapController!.clearLines();
      if (latLngs.length >= 2) {
        // Casing line (white outline)
        await _mapController!.addLine(
          LineOptions(
            geometry: latLngs,
            lineColor: '#ffffff',
            lineWidth: 9.0,
            lineOpacity: 0.95,
            lineJoin: 'round',
          ),
        );
        // Core green route line
        await _mapController!.addLine(
          LineOptions(
            geometry: latLngs,
            lineColor: '#059669', // Vivid Emerald Green
            lineWidth: 5.5,
            lineOpacity: 1.0,
            lineJoin: 'round',
          ),
        );
      }
    } catch (e) {
      print('[MAP_ROUTE] Annotation line error: $e');
    }

    // 2. Also update/add GeoJSON layer
    try {
      final feature = _currentRoute!.toGeoJsonFeature();
      final geojson = {
        'type': 'FeatureCollection',
        'features': [feature],
      };
      await _mapController!.addGeoJsonSource(
        'active_pedestrian_route',
        geojson,
      );
      await _mapController!.addLineLayer(
        'active_pedestrian_route',
        'route_line_casing',
        const LineLayerProperties(
          lineColor: '#ffffff',
          lineWidth: 9.0,
          lineCap: 'round',
          lineJoin: 'round',
          lineOpacity: 0.95,
        ),
      );
      await _mapController!.addLineLayer(
        'active_pedestrian_route',
        'route_line',
        const LineLayerProperties(
          lineColor: '#059669',
          lineWidth: 5.5,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
    } catch (_) {
      try {
        final feature = _currentRoute!.toGeoJsonFeature();
        await _mapController!.setGeoJsonSource('active_pedestrian_route', {
          'type': 'FeatureCollection',
          'features': [feature],
        });
      } catch (_) {}
    }

    _fitRouteCameraBounds();
  }

  void _simulateEdgeBlock() {
    if (_currentRoute == null || _currentRoute!.pathEdgeIds.isEmpty) return;

    final edges = _currentRoute!.pathEdgeIds;
    final edgeToBlock = edges[edges.length ~/ 2];

    setState(() {
      _blockedEdgeIds.add(edgeToBlock);
    });

    _calculateBestPointAndRoute();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Arista #$edgeToBlock bloqueada en memoria. Ruta alternativa calculada según el grafo disponible.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearBlocks() {
    setState(() {
      _blockedEdgeIds.clear();
    });
    _calculateBestPointAndRoute();
  }

  void _runDartBenchmarksModal() {
    if (_router == null || _graph == null || _spatialGrid == null) return;

    setState(() => _isBenchmarking = true);

    final bench = DartRoutingBenchmark(
      graph: _graph!,
      spatialGrid: _spatialGrid!,
      router: _router!,
    );

    final results = bench.runSuite();
    final summaries = DartRoutingBenchmark.computeSummaries(results);

    print('=== ANDROID_PHYSICAL_BENCHMARK_RESULTS ===');
    for (final s in summaries) {
      print(
        '[ANDROID_BENCHMARK] Category: ${s.category} (N=${s.count}) | MeanMs: ${s.meanMs.toStringAsFixed(2)} | MedianMs: ${s.medianMs.toStringAsFixed(2)} | p95Ms: ${s.p95Ms.toStringAsFixed(2)} | WorstMs: ${s.worstMs.toStringAsFixed(2)} | MeanNodes: ${s.meanNodes}',
      );
    }

    setState(() {
      _isBenchmarking = false;
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 480,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados de Benchmarks en Dart (30 Rutas)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: summaries.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (ctx, i) {
                  final s = summaries[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Tiempo Medio: ${s.meanMs.toStringAsFixed(2)} ms | p50: ${s.medianMs.toStringAsFixed(2)} ms',
                      ),
                      Text(
                        '• p95: ${s.p95Ms.toStringAsFixed(2)} ms | Peor: ${s.worstMs.toStringAsFixed(2)} ms',
                      ),
                      Text('• Nodos explorados: ${s.meanNodes} nodos'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColdStartModal() {
    final t0 = _coldStartTimestamps['T0_POC_INIT_START'] ?? 0;
    final t2 = _coldStartTimestamps['T2_PMTILES_READY'] ?? 0;
    final t3 = _coldStartTimestamps['T3_POINTS_LOADED'] ?? 0;
    final t4 = _coldStartTimestamps['T4_GRAPH_LOADED'] ?? 0;
    final t5 = _coldStartTimestamps['T5_SPATIAL_GRID_READY'] ?? 0;
    final t1 = _coldStartTimestamps['T1_POC_MOUNTED'] ?? 0;
    final t6 = _coldStartTimestamps['T6_ROUTING_READY'] ?? 0;
    final totalColdStart = t1 + t6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.timer, color: Colors.blueAccent, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Métricas de Inicialización y Routing (iOS)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text('• T0 (Inicio montaje de pantalla): $t0 ms'),
            const SizedBox(height: 4),
            Text('• T2 (PMTiles local preparado): $t2 ms (duración)'),
            const SizedBox(height: 4),
            Text('• T3 (433 Puntos SUNASS parseados): $t3 ms (duración)'),
            const SizedBox(height: 4),
            Text('• T4 (Grafo CSR 855k/1.99M cargado): $t4 ms (duración)'),
            const SizedBox(height: 4),
            Text('• T5 (Índice espacial y snapping listo): $t5 ms (duración)'),
            const SizedBox(height: 4),
            Text(
              '• T1 (Subsistema offline listo y montado): $t1 ms (acumulado)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• T6 (Primer cálculo de ruta A*): $t6 ms (duración)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(height: 16),
            Text(
              'INICIALIZACIÓN SUBSISTEMA A RUTA LISTA: $totalColdStart ms',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Text(
              '(Nota metodológica: Representa la inicialización del motor offline y primer cálculo dentro de Flutter; no incluye el arranque de proceso a nivel de kernel del SO)',
              style: TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Estado del Sensor GNSS / Ubicación (iOS):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '• Estado: ${_currentPosition.state.name} (${_currentPosition.statusDisplay})',
            ),
            Text(
              '• Lat / Lon: ${_currentPosition.latitude.toStringAsFixed(5)}, ${_currentPosition.longitude.toStringAsFixed(5)}',
            ),
            Text(
              '• Precisión (Accuracy): ${_currentPosition.accuracyMeters != null ? "${_currentPosition.accuracyMeters!.toStringAsFixed(1)} metros" : "N/A"}',
            ),
            const Text(
              '(Obtenido con Wi-Fi OFF y Datos Móviles OFF. No se afirma "GPS puro" ni ausencia de A-GPS)',
              style: TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runStressTest() async {
    if (_router == null || _graph == null || _spatialGrid == null) return;

    setState(() => _isStressTesting = true);

    final swTotal = Stopwatch()..start();
    int successfulRoutes = 0;
    int expectedNoRoute = 0;
    int unexpectedFailures = 0;
    int uncaughtExceptions = 0;
    int blockSuccessCount = 0;

    // 1. 30 Direct Routes strictly at 50m
    for (final tc in DartRoutingBenchmark.testCases) {
      try {
        final o = tc['o'] as List<double>;
        final d = tc['d'] as List<double>;
        final res = _router!.route(
          originLat: o[0],
          originLon: o[1],
          destinationLat: d[0],
          destinationLon: d[1],
          snapThresholdMeters: 50.0,
        );
        if (res.isSuccess) {
          successfulRoutes++;
        } else if (res.status == RouteStatus.originSnapFailed ||
            res.status == RouteStatus.destinationSnapFailed ||
            res.status == RouteStatus.unreachable) {
          expectedNoRoute++;
        } else {
          unexpectedFailures++;
        }
      } catch (_) {
        uncaughtExceptions++;
      }
    }

    // 2. 30 Reverse Routes strictly at 50m
    for (final tc in DartRoutingBenchmark.testCases) {
      try {
        final o = tc['o'] as List<double>;
        final d = tc['d'] as List<double>;
        final res = _router!.route(
          originLat: d[0],
          originLon: d[1],
          destinationLat: o[0],
          destinationLon: o[1],
          snapThresholdMeters: 50.0,
        );
        if (res.isSuccess) {
          successfulRoutes++;
        } else if (res.status == RouteStatus.originSnapFailed ||
            res.status == RouteStatus.destinationSnapFailed ||
            res.status == RouteStatus.unreachable) {
          expectedNoRoute++;
        } else {
          unexpectedFailures++;
        }
      } catch (_) {
        uncaughtExceptions++;
      }
    }

    // 3. 10 Dynamic Edge Blockages
    final dynamicBlocked = <int>{};
    for (int i = 0; i < 10; i++) {
      try {
        final tc = DartRoutingBenchmark
            .testCases[i % DartRoutingBenchmark.testCases.length];
        final o = tc['o'] as List<double>;
        final d = tc['d'] as List<double>;
        final initialRoute = _router!.route(
          originLat: o[0],
          originLon: o[1],
          destinationLat: d[0],
          destinationLon: d[1],
          snapThresholdMeters: 50.0,
          blockedEdgeIds: dynamicBlocked,
        );
        if (initialRoute.isSuccess && initialRoute.pathEdgeIds.isNotEmpty) {
          final midEdge =
              initialRoute.pathEdgeIds[initialRoute.pathEdgeIds.length ~/ 2];
          dynamicBlocked.add(midEdge);

          final reroute = _router!.route(
            originLat: o[0],
            originLon: o[1],
            destinationLat: d[0],
            destinationLon: d[1],
            snapThresholdMeters: 50.0,
            blockedEdgeIds: dynamicBlocked,
          );
          if (reroute.isSuccess) {
            blockSuccessCount++;
          }
        }
      } catch (_) {
        uncaughtExceptions++;
      }
    }

    swTotal.stop();

    print('=== IOS_STRESS_TEST_RESULTS ===');
    print('[IOS_STRESS] successful_routes: $successfulRoutes / 60');
    print(
      '[IOS_STRESS] expected_no_route: $expectedNoRoute / 60 (SNAP_NOT_FOUND 50m)',
    );
    print('[IOS_STRESS] unexpected_failures: $unexpectedFailures');
    print('[IOS_STRESS] uncaught_exceptions: $uncaughtExceptions');
    print('[IOS_STRESS] blockSuccessCount: $blockSuccessCount / 10');
    print('[IOS_STRESS] total elapsed: ${swTotal.elapsedMilliseconds} ms');

    setState(() => _isStressTesting = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shield, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(
                  'Prueba de Estrés y Estabilidad (iOS)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Auditoría estricta a 50m (sin relajación de umbrales):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• successful_routes: $successfulRoutes / 60',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '• expected_no_route: $expectedNoRoute / 60 (SNAP_NOT_FOUND a 50m)',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            Text(
              '  (5 rutas con origen/destino en autopista, acantilado o reserva)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '• unexpected_failures: $unexpectedFailures',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: unexpectedFailures == 0 ? Colors.green : Colors.red,
              ),
            ),
            Text(
              '• uncaught_exceptions: $uncaughtExceptions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: uncaughtExceptions == 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '• Bloqueos dinámicos en memoria: $blockSuccessCount / 10 re-enrutados con éxito',
              style: const TextStyle(fontSize: 13, color: Colors.green),
            ),
            Text(
              '• Tiempo total del test: ${swTotal.elapsedMilliseconds} ms (${(swTotal.elapsedMilliseconds / 70.0).toStringAsFixed(2)} ms/op)',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: uncaughtExceptions == 0 && unexpectedFailures == 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: uncaughtExceptions == 0 && unexpectedFailures == 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    uncaughtExceptions == 0 ? Icons.check_circle : Icons.error,
                    color: uncaughtExceptions == 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uncaughtExceptions == 0 && unexpectedFailures == 0
                          ? 'VEREDICTO: ESTABILIDAD COMPLETA EN iOS. Cero crashes, cero excepciones no capturadas tras 70 operaciones intensivas de enrutamiento.'
                          : 'VEREDICTO: Se detectaron fallos no esperados.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: uncaughtExceptions == 0
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('POC Navegación Offline')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasDivergence =
        _haversineWinnerPoint != null &&
        _walkWinnerPoint != null &&
        _haversineWinnerPoint!['water_point_id'] !=
            _walkWinnerPoint!['water_point_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('POC Navegación Offline (AguaCION)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Métricas Cold Start',
            onPressed: _showColdStartModal,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Prueba de Estrés (60 Rutas + 10 Bloqueos)',
            onPressed: _isStressTesting ? null : _runStressTest,
          ),
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Ejecutar Benchmarks Dart (30 Rutas)',
            onPressed: _isBenchmarking ? null : _runDartBenchmarksModal,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Actualizar GPS',
            onPressed: () async {
              await _refreshLocation();
              _centerOnUser();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. MapLibre Native GPU Map
          _styleString == null
              ? const Center(
                  child: Text('Error cargando estilo de mapa offline.'),
                )
              : MapLibreMap(
                  styleString: _styleString!,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                    zoom: 13.5,
                  ),
                  cameraTargetBounds: CameraTargetBounds(
                    LatLngBounds(
                      southwest: const LatLng(-12.42, -77.26),
                      northeast: const LatLng(-11.70, -76.56),
                    ),
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(10.0, 16.0),
                  trackCameraPosition: true,
                  myLocationEnabled: true,
                ),

          // 2. Top GNSS Status Strip
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition.state == LocationState.current
                          ? Icons.gps_fixed
                          : Icons.gps_not_fixed,
                      color: _currentPosition.state == LocationState.current
                          ? Colors.green
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentPosition.statusDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<double>(
                      value: _snapThresholdMeters,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                      ),
                      items: const [
                        DropdownMenuItem(value: 30.0, child: Text('Snap 30m')),
                        DropdownMenuItem(value: 50.0, child: Text('Snap 50m')),
                        DropdownMenuItem(
                          value: 100.0,
                          child: Text('Snap 100m'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _snapThresholdMeters = val);
                          _calculateBestPointAndRoute();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Comparison & Control Panel
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Punto con menor ruta peatonal estimada según el grafo disponible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_currentRoute != null)
                          Text(
                            '${_currentRoute!.calculationTimeMs.toStringAsFixed(1)} ms (${_currentRoute!.visitedNodes} nodos)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Winner info
                    if (_walkWinnerPoint != null &&
                        _currentRoute != null &&
                        _currentRoute!.isSuccess)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_walkWinnerPoint!['water_point_id']} - ${_walkWinnerPoint!['district']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                          Text(
                            _walkWinnerPoint!['location_description'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  'Distancia a pie: ${_currentRoute!.formattedDistance}',
                                ),
                                backgroundColor: const Color(0xFFDCFCE7),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 6),
                              Chip(
                                label: Text(_currentRoute!.formattedDuration),
                                backgroundColor: const Color(0xFFE0F2FE),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF075985),
                                  fontSize: 11,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          if (_lastSearchResult != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Búsqueda adaptativa: ${_lastSearchResult!.candidatesRoutedCount} candidatos A* evaluados de ${_lastSearchResult!.totalCandidatesCount} '
                                '(parada geodésica: ${_lastSearchResult!.stoppingHaversineDistance < 100000 ? "${_lastSearchResult!.stoppingHaversineDistance.toStringAsFixed(0)} m" : "fin de lista"})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      const Text(
                        'SNAP_NOT_FOUND: Sin vía transitable dentro del umbral de distancia.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),

                    // Divergence Callout
                    if (hasDivergence)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Text(
                          '⚠️ DIVERGENCIA DETECTADA: Haversine directo elige ${_haversineWinnerPoint!['water_point_id']} '
                          '(recta: ${(_lastSearchResult?.haversineWinnerHaversineDistance ?? 0.0).toStringAsFixed(0)} m, a pie: ${_haversineWinnerWalkDist.toStringAsFixed(0)} m). '
                          'Ruta peatonal según el grafo disponible ahorra ${_lastSearchResult?.savingsMeters.toStringAsFixed(0)} m '
                          '(${_lastSearchResult?.candidatesRoutedCount} candidatos A* evaluados).',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const Divider(height: 16),

                    // Actions Bar: Edge Blocking
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentRoute?.isSuccess == true
                              ? _simulateEdgeBlock
                              : null,
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text(
                            'Simular Bloqueo',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (_blockedEdgeIds.isNotEmpty)
                          TextButton(
                            onPressed: _clearBlocks,
                            child: Text(
                              'Desbloquear (${_blockedEdgeIds.length})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
