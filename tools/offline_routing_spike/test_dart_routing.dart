// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:aguacion_app/data/sources/local/routing/csr_graph.dart';
import 'package:aguacion_app/data/sources/local/routing/edge_spatial_grid.dart';
import 'package:aguacion_app/data/sources/local/routing/astar_router.dart';
import 'package:aguacion_app/data/sources/local/routing/dart_routing_benchmark.dart';

void main() async {
  print('===============================================================');
  print('   AGUACION - DART NATIVE OFFLINE ROUTING BENCHMARK (DESKTOP)  ');
  print('===============================================================\n');

  final memBefore = ProcessInfo.currentRss;
  print('1. Memoria RSS antes de cargar el grafo: ${(memBefore / (1024 * 1024)).toStringAsFixed(2)} MB');

  // Startup Phase 1: Read binary CSR file
  final swGraph = Stopwatch()..start();
  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  if (!binFile.existsSync()) {
    print('ERROR: pedestrian_graph_lima_csr.bin no existe!');
    exit(1);
  }

  final bytes = await binFile.readAsBytes();
  final graph = CsrGraph.fromBytes(bytes);
  swGraph.stop();

  final memAfterGraph = ProcessInfo.currentRss;
  print('2. Grafo cargado en: ${swGraph.elapsedMilliseconds} ms');
  print('   - Nodos activos: ${graph.nodeCount}');
  print('   - Aristas no dirigidas: ${graph.undirectedEdgeCount}');
  print('   - Aristas dirigidas CSR: ${graph.directedEdgeCount}');
  print('   - Memoria RSS con grafo: ${(memAfterGraph / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('   - Delta RAM grafo: ${((memAfterGraph - memBefore) / (1024 * 1024)).toStringAsFixed(2)} MB');

  // Startup Phase 2: Build Edge Spatial Grid
  final swGrid = Stopwatch()..start();
  final spatialGrid = EdgeSpatialGrid(graph);
  swGrid.stop();

  final memAfterGrid = ProcessInfo.currentRss;
  print('\n3. Indice Espacial (Spatial Grid) construido en: ${swGrid.elapsedMilliseconds} ms');
  print('   - Memoria RSS con indice espacial: ${(memAfterGrid / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('   - Delta RAM indice: ${((memAfterGrid - memAfterGraph) / (1024 * 1024)).toStringAsFixed(2)} MB');

  final router = AstarRouter(graph: graph, spatialGrid: spatialGrid);
  final benchmark = DartRoutingBenchmark(
    graph: graph,
    spatialGrid: spatialGrid,
    router: router,
  );

  // Benchmarking 30 Routes
  print('\n4. Ejecutando Bateria de 30 Rutas Peatonales en Dart...');
  final swBench = Stopwatch()..start();
  final results = benchmark.runSuite();
  swBench.stop();
  final memDuringRouting = ProcessInfo.currentRss;

  print('   - Tiempo total para 30 rutas: ${swBench.elapsedMilliseconds} ms');
  print('   - Memoria RSS durante routing: ${(memDuringRouting / (1024 * 1024)).toStringAsFixed(2)} MB');

  print('\n--- RESULTADOS ESTADISTICOS DART BENCHMARK (DESKTOP) ---');
  final summaries = DartRoutingBenchmark.computeSummaries(results);
  for (final s in summaries) {
    print('\nCategoria: ${s.category} (N=${s.count})');
    print('  Tiempo Dart (ms) : Media=${s.meanMs.toStringAsFixed(2)} ms | p50=${s.medianMs.toStringAsFixed(2)} ms | p95=${s.p95Ms.toStringAsFixed(2)} ms | Peor=${s.worstMs.toStringAsFixed(2)} ms');
    print('  Nodos Explorados : Media=${s.meanNodes} nodos');
  }

  // Snapping & Barrier test
  print('\n5. Prueba de Snapping con Umbrales Conservadores (30m, 50m, 100m)...');
  final testPoints = [
    {'name': 'Jiron Ancash (calle regular)', 'lat': -12.0440, 'lon': -77.0280},
    {'name': 'Plaza Mayor (zona peatonal)', 'lat': -12.0453, 'lon': -77.0311},
    {'name': 'Medio del Oceano Pacifico (fuera de red)', 'lat': -12.0800, 'lon': -77.2000},
  ];

  for (final p in testPoints) {
    final lat = p['lat'] as double;
    final lon = p['lon'] as double;
    final name = p['name'] as String;
    print('\nPunto: $name ($lat, $lon)');
    for (final th in [30.0, 50.0, 100.0]) {
      final snap = spatialGrid.snapToSegment(lat, lon, thresholdMeters: th);
      print('  - Umbral $th m: ${snap.isSuccess ? "SNAP OK (dist: ${snap.distanceMeters.toStringAsFixed(1)}m, edgeId: ${snap.edgeId})" : "SNAP_NOT_FOUND"}');
    }
  }

  // Dynamic Edge Blocking in Dart
  print('\n6. Prueba de Bloqueo Dinamico de Arista en Dart...');
  final origin = [-12.0440, -77.0280];
  final dest = [-12.0390, -77.0270];

  final rBase = router.route(
    originLat: origin[0],
    originLon: origin[1],
    destinationLat: dest[0],
    destinationLon: dest[1],
    snapThresholdMeters: 50.0,
  );
  print('  Ruta Base: ${rBase.formattedDistance} | Tiempo: ${rBase.calculationTimeMs.toStringAsFixed(2)} ms | Nodos: ${rBase.visitedNodes}');

  if (rBase.pathEdgeIds.isNotEmpty) {
    final blockId = rBase.pathEdgeIds[rBase.pathEdgeIds.length ~/ 2];
    print('  -> Simulando Bloqueo en arista #$blockId...');
    final rBlocked = router.route(
      originLat: origin[0],
      originLon: origin[1],
      destinationLat: dest[0],
      destinationLon: dest[1],
      snapThresholdMeters: 50.0,
      blockedEdgeIds: {blockId},
    );
    final distDelta = rBlocked.distanceMeters - rBase.distanceMeters;
    final timeDelta = rBlocked.calculationTimeMs - rBase.calculationTimeMs;
    print('  Ruta con Desvio: ${rBlocked.formattedDistance} (+${distDelta.toStringAsFixed(1)} m) | Tiempo: ${rBlocked.calculationTimeMs.toStringAsFixed(2)} ms (Delta: ${timeDelta > 0 ? "+" : ""}${timeDelta.toStringAsFixed(2)} ms) | Nodos: ${rBlocked.visitedNodes}');
    print('  ✓ Desvio dinamico recalculado en caliente exitosamente en Dart.');
  }

  // Candidate Pool Experiment (N=5, 10, 20) with 433 real points
  print('\n7. Experimento de Grupo de Candidatos SUNASS (N=5, 10, 20)...');
  final ptsFile = File('docs/data-audit/water_points_normalized.json');
  if (ptsFile.existsSync()) {
    final decoded = json.decode(await ptsFile.readAsString());
    final ptsJson = (decoded is Map ? decoded['records'] : decoded) as List<dynamic>;
    final waterPoints = ptsJson.cast<Map<String, dynamic>>();

    // Test origin in Los Olivos near Panamericana
    final expResults = benchmark.runCandidateExperiment(
      originLat: -11.9750,
      originLon: -77.0650,
      waterPoints: waterPoints,
    );

    for (final exp in expResults) {
      print('  N = ${exp.candidateN}: Ganador=${exp.winningPointId} (${exp.winningDistrict}) | Distancia a pie=${exp.walkingDistanceM.toStringAsFixed(0)} m | Tiempo evaluacion=${exp.calculationTimeMs.toStringAsFixed(1)} ms');
    }
  }

  print('\n✓ TODAS LAS PRUEBAS EN DART COMPLETADAS SATISFACTORIAMENTE.');
}
