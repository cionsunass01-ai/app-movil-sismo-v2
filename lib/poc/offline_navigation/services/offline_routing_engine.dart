import 'dart:convert';
import 'package:flutter/services.dart';
import '../benchmarks/dart_routing_benchmark.dart';
import '../graph/csr_graph.dart';
import '../models/route_result.dart';
import '../routing/astar_router.dart';
import '../routing/adaptive_water_point_search.dart';
import '../spatial/edge_spatial_grid.dart';
import 'pmtiles_manager.dart';

/// Singleton manager for the validated offline pedestrian routing engine.
///
/// Keeps the in-memory CSR graph (855k nodes, 1.99M edges), Spatial Grid,
/// and normalized water point dataset in memory to guarantee instant
/// calculations (< 5 ms) across the entire citizen application.
class OfflineRoutingEngine {
  static OfflineRoutingEngine? _instance;
  static OfflineRoutingEngine get instance =>
      _instance ??= OfflineRoutingEngine._();

  OfflineRoutingEngine._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? styleString;
  CsrGraph? graph;
  EdgeSpatialGrid? spatialGrid;
  AstarRouter? router;
  AdaptiveWaterPointSearch? adaptiveSearch;
  List<Map<String, dynamic>> waterPoints = [];
  final Map<String, int> coldStartTimestamps = {};

  Future<void> ensureInitialized({
    void Function(String message)? onProgress,
  }) async {
    if (_isInitialized) return;

    final swTotal = Stopwatch()..start();
    coldStartTimestamps['T0_INIT_START'] = 0;

    // 1. Prepare PMTiles style JSON
    onProgress?.call('Preparando mapa vectorial local PMTiles...');
    final swPmtiles = Stopwatch()..start();
    styleString = await PmtilesManager.getOfflineStyleString();
    swPmtiles.stop();
    coldStartTimestamps['T2_PMTILES_READY'] = swPmtiles.elapsedMilliseconds;

    // 2. Load 433 Water Points
    onProgress?.call('Cargando 433 puntos oficiales de agua...');
    final swPoints = Stopwatch()..start();
    final ptsStr = await rootBundle.loadString(
      'assets/poc/data/water_points_normalized.json',
    );
    final ptsDecoded = json.decode(ptsStr);
    waterPoints =
        ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded)
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    swPoints.stop();
    coldStartTimestamps['T3_POINTS_LOADED'] = swPoints.elapsedMilliseconds;

    // 3. Load CSR Binary Graph
    try {
      onProgress?.call('Cargando grafo peatonal CSR...');
      final swGraph = Stopwatch()..start();
      final graphByteData = await rootBundle.load(
        'assets/poc/routing/pedestrian_graph_lima_csr.bin',
      );
      final graphBytes = graphByteData.buffer.asUint8List(
        graphByteData.offsetInBytes,
        graphByteData.lengthInBytes,
      );
      graph = CsrGraph.fromBytes(graphBytes);
      swGraph.stop();
      coldStartTimestamps['T4_GRAPH_LOADED'] = swGraph.elapsedMilliseconds;

      // 4. Build Spatial Grid for edge snapping
      onProgress?.call('Construyendo índice espacial para snapping...');
      final swGrid = Stopwatch()..start();
      spatialGrid = EdgeSpatialGrid(graph!);
      router = AstarRouter(graph: graph!, spatialGrid: spatialGrid!);
      adaptiveSearch = AdaptiveWaterPointSearch(router!);
      swGrid.stop();
      coldStartTimestamps['T5_SPATIAL_GRID_READY'] = swGrid.elapsedMilliseconds;
    } catch (e) {
      // On web, downloading 32MB binary over HTTP may time out or fail.
      // The map and points still render cleanly even without local routing.
      // ignore: avoid_print
      print('Aviso: Grafo peatonal offline (32MB) no cargado en navegador: $e');
    }

    coldStartTimestamps['T1_ENGINE_READY'] = swTotal.elapsedMilliseconds;
    _isInitialized = true;
  }

  /// Finds the optimal nearest water point and calculates the pedestrian route
  AdaptiveSearchResult? searchNearest({
    required double originLat,
    required double originLon,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  }) {
    if (!_isInitialized || adaptiveSearch == null || waterPoints.isEmpty) {
      return null;
    }

    return adaptiveSearch!.search(
      originLat: originLat,
      originLon: originLon,
      waterPoints: waterPoints,
      snapThresholdMeters: snapThresholdMeters,
      blockedEdgeIds: blockedEdgeIds,
    );
  }

  /// Computes a pedestrian route to a specific destination point
  RouteResult? routeToPoint({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  }) {
    if (!_isInitialized || router == null) {
      return null;
    }

    return router!.route(
      originLat: originLat,
      originLon: originLon,
      destinationLat: destinationLat,
      destinationLon: destinationLon,
      snapThresholdMeters: snapThresholdMeters,
      blockedEdgeIds: blockedEdgeIds,
    );
  }

  /// Runs the 30-route Dart benchmark suite and returns human-readable summaries
  List<BenchmarkCategorySummary> runBenchmarks() {
    if (!_isInitialized ||
        router == null ||
        graph == null ||
        spatialGrid == null) {
      return [];
    }

    final bench = DartRoutingBenchmark(
      graph: graph!,
      spatialGrid: spatialGrid!,
      router: router!,
    );
    final results = bench.runSuite();
    return DartRoutingBenchmark.computeSummaries(results);
  }
}
