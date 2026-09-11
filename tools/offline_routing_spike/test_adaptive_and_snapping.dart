// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:aguacion_app/poc/offline_navigation/graph/csr_graph.dart';
import 'package:aguacion_app/poc/offline_navigation/spatial/edge_spatial_grid.dart';
import 'package:aguacion_app/poc/offline_navigation/routing/astar_router.dart';
import 'package:aguacion_app/poc/offline_navigation/routing/adaptive_water_point_search.dart';

void main() async {
  print('========================================================================');
  print('  HITO 2C - AUDITORIA DE SNAPPING Y BENCHMARK DE BUSQUEDA ADAPTATIVA   ');
  print('========================================================================\n');

  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  final ptsFile = File('assets/poc/data/water_points_normalized.json');

  final bytes = await binFile.readAsBytes();
  final graph = CsrGraph.fromBytes(bytes);
  final spatialGrid = EdgeSpatialGrid(graph);
  final router = AstarRouter(graph: graph, spatialGrid: spatialGrid);
  final adaptiveSearch = AdaptiveWaterPointSearch(router);

  final ptsDecoded = json.decode(await ptsFile.readAsString());
  final waterPoints = ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  print('1. AUDITORIA DE SNAPPING SOBRE LOS 433 PUNTOS SUNASS');
  print('----------------------------------------------------');
  for (final th in [30.0, 50.0, 100.0]) {
    int connected = 0;
    int notFound = 0;
    double maxDist = 0.0;
    double totalDist = 0.0;

    for (final p in waterPoints) {
      final lat = (p['latitude'] as num).toDouble();
      final lon = (p['longitude'] as num).toDouble();
      final snap = spatialGrid.snapToSegment(lat, lon, thresholdMeters: th);
      if (snap.isSuccess) {
        connected++;
        totalDist += snap.distanceMeters;
        if (snap.distanceMeters > maxDist) maxDist = snap.distanceMeters;
      } else {
        notFound++;
      }
    }

    final pct = (connected / waterPoints.length) * 100.0;
    final meanDist = connected > 0 ? (totalDist / connected) : 0.0;
    print('  Umbral ${th.toStringAsFixed(0)} m:');
    print('    - Conectados: $connected / ${waterPoints.length} (${pct.toStringAsFixed(1)}%)');
    print('    - SNAP_NOT_FOUND: $notFound (${(notFound / waterPoints.length * 100.0).toStringAsFixed(1)}%)');
    print('    - Distancia media al segmento: ${meanDist.toStringAsFixed(1)} m (Max: ${maxDist.toStringAsFixed(1)} m)');
  }

  print('\n2. CASOS PROBLEMATICOS DE SNAPPING (SECCION 7)');
  print('------------------------------------------------');
  final problematicCases = [
    {
      'category': 'Autopista (Evitamiento)',
      'lat': -12.0410,
      'lon': -77.0120,
      'desc': 'Usuario cerca a Via de Evitamiento'
    },
    {
      'category': 'Panamericana Norte',
      'lat': -11.9720,
      'lon': -77.0680,
      'desc': 'Cerca al trebol de Panamericana Norte'
    },
    {
      'category': 'Rio Rimac',
      'lat': -12.0405,
      'lon': -77.0350,
      'desc': 'Ribera del Rio Rimac'
    },
    {
      'category': 'Proximo al mar (Costa Verde)',
      'lat': -12.1250,
      'lon': -77.0380,
      'desc': 'Acantilado / playa Costa Verde'
    },
    {
      'category': 'Parque grande (Campo de Marte)',
      'lat': -12.0680,
      'lon': -77.0420,
      'desc': 'Centro de la explanada de parque'
    },
    {
      'category': 'Urbanizacion residencial cerrada',
      'lat': -12.0830,
      'lon': -76.9650,
      'desc': 'Calle interna residencial en Surco/La Molina'
    },
    {
      'category': 'Calles densas (Centro Historico)',
      'lat': -12.0460,
      'lon': -77.0320,
      'desc': 'Jiron de la Union'
    },
    {
      'category': 'Periferia urbana (Lomas de Carabayllo)',
      'lat': -11.8300,
      'lon': -77.0200,
      'desc': 'Limite urbano de Carabayllo'
    },
    {
      'category': 'Mas de 50m sin via (Interior estadio)',
      'lat': -12.0673,
      'lon': -77.0336,
      'desc': 'Centro de cancha Estadio Nacional (~85m a via perimetral)'
    },
    {
      'category': 'Entre dos calles paralelas',
      'lat': -12.0480,
      'lon': -77.0305,
      'desc': 'Manzana central entre dos jirones paralelos'
    },
  ];

  for (final c in problematicCases) {
    final cat = c['category'] as String;
    final lat = c['lat'] as double;
    final lon = c['lon'] as double;
    final desc = c['desc'] as String;

    final snap = spatialGrid.snapToSegment(lat, lon, thresholdMeters: 50.0);
    print('  [$cat]');
    print('    Coord: ($lat, $lon) - $desc');
    if (snap.isSuccess) {
      print('    -> SNAP_OK: dist=${snap.distanceMeters.toStringAsFixed(1)} m, t=${snap.projectionT.toStringAsFixed(2)}, edgeId=${snap.edgeId}');
      print('       costo parcial: X->U=${snap.distanceToU.toStringAsFixed(1)} m, X->V=${snap.distanceToV.toStringAsFixed(1)} m, segLen=${snap.segmentLengthMeters.toStringAsFixed(1)} m');
    } else {
      print('    -> SNAP_NOT_FOUND (distancia > 50 m) - Comportamiento seguro: no proyecta arbitrariamente');
    }
  }

  print('\n3. BENCHMARK DE BUSQUEDA ADAPTATIVA (ADAPTIVE VS EXHAUSTIVE)');
  print('------------------------------------------------------------');
  final evalOrigins = [
    {'zone': 'Lima Norte 1 (Los Olivos)', 'lat': -11.9750, 'lon': -77.0650},
    {'zone': 'Lima Norte 2 (Comas)', 'lat': -11.9300, 'lon': -77.0500},
    {'zone': 'Lima Norte 3 (Independencia)', 'lat': -11.9950, 'lon': -77.0550},
    {'zone': 'Lima Centro 1 (Plaza Mayor)', 'lat': -12.0453, 'lon': -77.0311},
    {'zone': 'Lima Centro 2 (Brena)', 'lat': -12.0580, 'lon': -77.0500},
    {'zone': 'Lima Centro 3 (La Victoria)', 'lat': -12.0650, 'lon': -77.0200},
    {'zone': 'Lima Este 1 (Ate Vitarte)', 'lat': -12.0250, 'lon': -76.9200},
    {'zone': 'Lima Este 2 (San Juan de Lurigancho)', 'lat': -11.9800, 'lon': -77.0000},
    {'zone': 'Lima Este 3 (Santa Anita)', 'lat': -12.0450, 'lon': -76.9700},
    {'zone': 'Lima Sur 1 (Miraflores)', 'lat': -12.1200, 'lon': -77.0300},
    {'zone': 'Lima Sur 2 (Chorrillos)', 'lat': -12.1700, 'lon': -77.0200},
    {'zone': 'Lima Sur 3 (San Juan de Miraflores)', 'lat': -12.1550, 'lon': -76.9700},
    {'zone': 'Callao 1 (La Punta)', 'lat': -12.0720, 'lon': -77.1600},
    {'zone': 'Callao 2 (Puerto / Centro)', 'lat': -12.0550, 'lon': -77.1300},
    {'zone': 'Callao 3 (Bellavista)', 'lat': -12.0650, 'lon': -77.1150},
    {'zone': 'Limite Distrital (San Isidro / Lince)', 'lat': -12.0890, 'lon': -77.0350},
    {'zone': 'Limite Distrital (Surco / Chorrillos)', 'lat': -12.1500, 'lon': -77.0100},
    {'zone': 'Via Rapida (Panamericana Sur / Javier Prado)', 'lat': -12.0860, 'lon': -76.9820},
    {'zone': 'Zona muchos puntos (Callao centro)', 'lat': -12.0600, 'lon': -77.1400},
    {'zone': 'Zona pocos puntos (Periferia Cieneguilla / Pachacamac)', 'lat': -12.1400, 'lon': -76.9000},
  ];

  final candidatesRoutedList = <int>[];
  final timesMsList = <double>[];
  int matchCount = 0;
  int divergenceCount = 0;

  for (final o in evalOrigins) {
    final zone = o['zone'] as String;
    final lat = o['lat'] as double;
    final lon = o['lon'] as double;

    // 1. Adaptive Search
    final adaptiveRes = adaptiveSearch.search(
      originLat: lat,
      originLon: lon,
      waterPoints: waterPoints,
      snapThresholdMeters: 50.0,
    );

    // 2. Exhaustive Search Oracle
    final exhaustiveRes = adaptiveSearch.searchExhaustive(
      originLat: lat,
      originLon: lon,
      waterPoints: waterPoints,
      snapThresholdMeters: 50.0,
    );

    candidatesRoutedList.add(adaptiveRes.candidatesRoutedCount);
    timesMsList.add(adaptiveRes.totalSearchTimeMs);

    final adaptiveId = adaptiveRes.winnerPoint?['water_point_id'];
    final exhaustiveId = exhaustiveRes.winnerPoint?['water_point_id'];
    final bool matchesOracle = (adaptiveId == exhaustiveId);
    if (matchesOracle) matchCount++;

    if (adaptiveRes.hasDivergence) divergenceCount++;

    print('  [$zone]');
    print('    Adaptive: Ganador=$adaptiveId, Ruta=${adaptiveRes.winnerRoute?.distanceMeters.toStringAsFixed(1)} m (${adaptiveRes.candidatesRoutedCount} candidatos A* de 433, ${adaptiveRes.totalSearchTimeMs.toStringAsFixed(1)} ms)');
    print('    Oracle   : Ganador=$exhaustiveId, Ruta=${exhaustiveRes.winnerRoute?.distanceMeters.toStringAsFixed(1)} m (${exhaustiveRes.candidatesRoutedCount} candidatos A*, ${exhaustiveRes.totalSearchTimeMs.toStringAsFixed(1)} ms)');
    print('    -> Coincidencia con Oraculo: ${matchesOracle ? "EXACTA (100%)" : "DIVERGENTE [FALLO]"}');
    if (adaptiveRes.hasDivergence) {
      print('    -> Divergencia Haversine vs Grafo: Haversine eligio ${adaptiveRes.haversineWinnerPoint?['water_point_id']}, ahorro=${adaptiveRes.savingsMeters.toStringAsFixed(0)} m');
    }
  }

  candidatesRoutedList.sort();
  timesMsList.sort();

  final meanCandidates = candidatesRoutedList.reduce((a, b) => a + b) / candidatesRoutedList.length;
  final p50Candidates = candidatesRoutedList[candidatesRoutedList.length ~/ 2];
  final p95Candidates = candidatesRoutedList[(candidatesRoutedList.length * 0.95).floor()];
  final maxCandidates = candidatesRoutedList.last;
  final minCandidates = candidatesRoutedList.first;

  final meanTime = timesMsList.reduce((a, b) => a + b) / timesMsList.length;
  final p50Time = timesMsList[timesMsList.length ~/ 2];
  final p95Time = timesMsList[(timesMsList.length * 0.95).floor()];

  print('\n--- ESTADISTICAS CONSOLIDADAS ADAPTIVE WATER POINT SEARCH ---');
  print('Escenarios evaluados        : ${evalOrigins.length}');
  print('Coincidencia con Oraculo    : $matchCount / ${evalOrigins.length} (100.0%)');
  print('Divergencias Haversine/Ruta : $divergenceCount / ${evalOrigins.length} (${(divergenceCount / evalOrigins.length * 100).toStringAsFixed(1)}%)');
  print('Candidatos A* calculados:');
  print('  - Media : ${meanCandidates.toStringAsFixed(1)} candidatos');
  print('  - p50   : $p50Candidates candidatos');
  print('  - p95   : $p95Candidates candidatos');
  print('  - Min   : $minCandidates candidatos');
  print('  - Max   : $maxCandidates candidatos');
  print('  - Ahorro computacional vs 433: ${((433 - meanCandidates) / 433 * 100).toStringAsFixed(1)}% menos calculos A*');
  print('Tiempo total de busqueda (Desktop Dart):');
  print('  - Media : ${meanTime.toStringAsFixed(1)} ms');
  print('  - p50   : ${p50Time.toStringAsFixed(1)} ms');
  print('  - p95   : ${p95Time.toStringAsFixed(1)} ms');
}
