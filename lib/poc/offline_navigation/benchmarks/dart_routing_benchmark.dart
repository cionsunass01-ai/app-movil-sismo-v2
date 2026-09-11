import 'dart:math';
import '../graph/csr_graph.dart';
import '../models/route_result.dart';
import '../routing/astar_router.dart';
import '../spatial/edge_spatial_grid.dart';

class BenchmarkItemResult {
  final String name;
  final String category;
  final double distanceMeters;
  final double timeMs;
  final int visitedNodes;

  BenchmarkItemResult({
    required this.name,
    required this.category,
    required this.distanceMeters,
    required this.timeMs,
    required this.visitedNodes,
  });
}

class BenchmarkCategorySummary {
  final String category;
  final int count;
  final double meanMs;
  final double medianMs;
  final double p95Ms;
  final double worstMs;
  final int meanNodes;

  BenchmarkCategorySummary({
    required this.category,
    required this.count,
    required this.meanMs,
    required this.medianMs,
    required this.p95Ms,
    required this.worstMs,
    required this.meanNodes,
  });
}

class CandidateExperimentResult {
  final int candidateN;
  final String winningPointId;
  final String winningDistrict;
  final double walkingDistanceM;
  final double calculationTimeMs;

  CandidateExperimentResult({
    required this.candidateN,
    required this.winningPointId,
    required this.winningDistrict,
    required this.walkingDistanceM,
    required this.calculationTimeMs,
  });
}

class DartRoutingBenchmark {
  final CsrGraph graph;
  final EdgeSpatialGrid spatialGrid;
  final AstarRouter router;

  DartRoutingBenchmark({
    required this.graph,
    required this.spatialGrid,
    required this.router,
  });

  /// 30 Real Route Test Cases distributed across Lima & Callao (10 short, 10 medium, 10 long)
  static final List<Map<String, dynamic>> testCases = [
    // 10 Short Routes (~400m - 1.5km)
    {
      'cat': 'Cortas',
      'name': 'Plaza Mayor -> Santo Domingo (Centro)',
      'o': [-12.0453, -77.0311],
      'd': [-12.0440, -77.0345],
    },
    {
      'cat': 'Cortas',
      'name': 'Chucuito -> Plaza Grau (Callao)',
      'o': [-12.0620, -77.1550],
      'd': [-12.0570, -77.1480],
    },
    {
      'cat': 'Cortas',
      'name': 'Tupac Amaru -> San Felipe (Comas)',
      'o': [-11.9350, -77.0580],
      'd': [-11.9280, -77.0530],
    },
    {
      'cat': 'Cortas',
      'name': 'Parque Kennedy -> Malecon (Miraflores)',
      'o': [-12.1215, -77.0298],
      'd': [-12.1265, -77.0360],
    },
    {
      'cat': 'Cortas',
      'name': 'Hosp. Rebagliati -> Campo de Marte (Jesus Maria)',
      'o': [-12.0790, -77.0420],
      'd': [-12.0710, -77.0410],
    },
    {
      'cat': 'Cortas',
      'name': 'Jiron Ancash -> Congreso (Cercado)',
      'o': [-12.0460, -77.0260],
      'd': [-12.0475, -77.0250],
    },
    {
      'cat': 'Cortas',
      'name': 'Av. Larco -> Parque del Amor (Miraflores)',
      'o': [-12.1280, -77.0310],
      'd': [-12.1240, -77.0380],
    },
    {
      'cat': 'Cortas',
      'name': 'Municipalidad VES -> Plaza Bolognesi (VES)',
      'o': [-12.2050, -76.9400],
      'd': [-12.2100, -76.9450],
    },
    {
      'cat': 'Cortas',
      'name': 'Alameda Chabuca Granda -> Puente Trujillo',
      'o': [-12.0440, -77.0290],
      'd': [-12.0415, -77.0280],
    },
    {
      'cat': 'Cortas',
      'name': 'Plaza Manco Capac -> Gamarra (La Victoria)',
      'o': [-12.0620, -77.0280],
      'd': [-12.0660, -77.0190],
    },

    // 10 Medium Routes (~2.5km - 5km)
    {
      'cat': 'Medias',
      'name': 'Plaza Mayor -> Campo de Marte (Centro)',
      'o': [-12.0453, -77.0311],
      'd': [-12.0680, -77.0410],
    },
    {
      'cat': 'Medias',
      'name': 'Bellavista -> Minka (Callao)',
      'o': [-12.0600, -77.1250],
      'd': [-12.0430, -77.1180],
    },
    {
      'cat': 'Medias',
      'name': 'Tupac Amaru -> Metro Belaunde (Comas)',
      'o': [-11.9350, -77.0580],
      'd': [-11.9150, -77.0500],
    },
    {
      'cat': 'Medias',
      'name': 'VES Sector 3 -> Hosp. Uldarico (VES)',
      'o': [-12.2050, -76.9400],
      'd': [-12.1850, -76.9550],
    },
    {
      'cat': 'Medias',
      'name': 'Carretera Central -> Ceres (Ate)',
      'o': [-12.0280, -76.9150],
      'd': [-12.0380, -76.9380],
    },
    {
      'cat': 'Medias',
      'name': 'Zarate -> Canto Grande (SJL)',
      'o': [-12.0250, -77.0050],
      'd': [-11.9950, -77.0000],
    },
    {
      'cat': 'Medias',
      'name': 'Plaza San Miguel -> Univ. Catolica (PUCP)',
      'o': [-12.0780, -77.0800],
      'd': [-12.0690, -77.0800],
    },
    {
      'cat': 'Medias',
      'name': 'Ovalo Gutierrez -> Huaca Pucllana (Miraflores)',
      'o': [-12.1100, -77.0360],
      'd': [-12.1110, -77.0290],
    },
    {
      'cat': 'Medias',
      'name': 'Av. Brasil -> Hosp. del Nino (Brena)',
      'o': [-12.0850, -77.0520],
      'd': [-12.0650, -77.0460],
    },
    {
      'cat': 'Medias',
      'name': 'Los Olivos Pro -> MegaPlaza (Independencia)',
      'o': [-11.9600, -77.0700],
      'd': [-11.9900, -77.0600],
    },

    // 10 Long Routes (~5km - 12km)
    {
      'cat': 'Largas',
      'name': 'Plaza Mayor Lima -> Plaza San Miguel',
      'o': [-12.0453, -77.0311],
      'd': [-12.0780, -77.0800],
    },
    {
      'cat': 'Largas',
      'name': 'Alameda Rimac -> Municipalidad Los Olivos',
      'o': [-12.0360, -77.0250],
      'd': [-11.9920, -77.0710],
    },
    {
      'cat': 'Largas',
      'name': 'Centro Callao -> Costanera San Miguel',
      'o': [-12.0570, -77.1480],
      'd': [-12.0850, -77.0950],
    },
    {
      'cat': 'Largas',
      'name': 'Surco Higuereta -> Malecon Chorrillos',
      'o': [-12.1350, -77.0010],
      'd': [-12.1650, -77.0280],
    },
    {
      'cat': 'Largas',
      'name': 'Zarate SJL -> Santa Anita Mercado Mayorista',
      'o': [-12.0250, -77.0050],
      'd': [-12.0480, -76.9720],
    },
    {
      'cat': 'Largas',
      'name': 'Estadio Nacional -> San Isidro Centro Financiero',
      'o': [-12.0670, -77.0330],
      'd': [-12.0950, -77.0280],
    },
    {
      'cat': 'Largas',
      'name': 'Chorrillos Pantanos de Villa -> Barranco Malecon',
      'o': [-12.2000, -77.0100],
      'd': [-12.1500, -77.0250],
    },
    {
      'cat': 'Largas',
      'name': 'Plaza Grau Callao -> Aeropuerto Jorge Chavez',
      'o': [-12.0570, -77.1480],
      'd': [-12.0220, -77.1120],
    },
    {
      'cat': 'Largas',
      'name': 'Puente Piedra Zapallal -> Ancon Malecon',
      'o': [-11.8300, -77.1150],
      'd': [-11.7750, -77.1750],
    },
    {
      'cat': 'Largas',
      'name': 'Vitarte Centro -> Santa Clara Ate',
      'o': [-12.0350, -76.9200],
      'd': [-12.0150, -76.8850],
    },
  ];

  /// Executes all 30 benchmarks and compiles statistical metrics
  List<BenchmarkItemResult> runSuite() {
    final results = <BenchmarkItemResult>[];

    for (final tc in testCases) {
      final o = tc['o'] as List<double>;
      final d = tc['d'] as List<double>;
      final res = router.route(
        originLat: o[0],
        originLon: o[1],
        destinationLat: d[0],
        destinationLon: d[1],
        snapThresholdMeters: 50.0,
      );

      results.add(
        BenchmarkItemResult(
          name: tc['name'] as String,
          category: tc['cat'] as String,
          distanceMeters: res.distanceMeters,
          timeMs: res.calculationTimeMs,
          visitedNodes: res.visitedNodes,
        ),
      );
    }
    return results;
  }

  static List<BenchmarkCategorySummary> computeSummaries(
    List<BenchmarkItemResult> results,
  ) {
    final categories = ['Cortas', 'Medias', 'Largas'];
    final summaries = <BenchmarkCategorySummary>[];

    for (final cat in categories) {
      final items = results.where((r) => r.category == cat).toList();
      if (items.isEmpty) continue;

      final times = items.map((r) => r.timeMs).toList()..sort();
      final nodes = items.map((r) => r.visitedNodes).toList();

      final meanMs = times.reduce((a, b) => a + b) / times.length;
      final medianMs = times[times.length ~/ 2];
      final p95Index = min(times.length - 1, (times.length * 0.95).floor());
      final p95Ms = times[p95Index];
      final worstMs = times.last;
      final meanNodes = nodes.reduce((a, b) => a + b) ~/ nodes.length;

      summaries.add(
        BenchmarkCategorySummary(
          category: cat,
          count: items.length,
          meanMs: meanMs,
          medianMs: medianMs,
          p95Ms: p95Ms,
          worstMs: worstMs,
          meanNodes: meanNodes,
        ),
      );
    }

    // Overall summary
    final allTimes = results.map((r) => r.timeMs).toList()..sort();
    final allNodes = results.map((r) => r.visitedNodes).toList();
    final meanMs = allTimes.reduce((a, b) => a + b) / allTimes.length;
    final medianMs = allTimes[allTimes.length ~/ 2];
    final p95Index = min(allTimes.length - 1, (allTimes.length * 0.95).floor());
    final p95Ms = allTimes[p95Index];
    final worstMs = allTimes.last;
    final meanNodes = allNodes.reduce((a, b) => a + b) ~/ allNodes.length;

    summaries.add(
      BenchmarkCategorySummary(
        category: 'Total General (30 rutas)',
        count: results.length,
        meanMs: meanMs,
        medianMs: medianMs,
        p95Ms: p95Ms,
        worstMs: worstMs,
        meanNodes: meanNodes,
      ),
    );

    return summaries;
  }

  /// Evaluates whether increasing the candidate pool N (N=5, 10, 20) alters the optimal walking destination
  List<CandidateExperimentResult> runCandidateExperiment({
    required double originLat,
    required double originLon,
    required List<Map<String, dynamic>> waterPoints,
  }) {
    // 1. Calculate straight-line Haversine to all 433 points
    final withHaversine =
        waterPoints.map((p) {
          final pLat = (p['latitude'] as num).toDouble();
          final pLon = (p['longitude'] as num).toDouble();
          final h = EdgeSpatialGrid.haversineMeters(
            originLat,
            originLon,
            pLat,
            pLon,
          );
          return {...p, 'haversine_m': h};
        }).toList()..sort(
          (a, b) => (a['haversine_m'] as double).compareTo(
            b['haversine_m'] as double,
          ),
        );

    final results = <CandidateExperimentResult>[];

    for (final n in [5, 10, 20]) {
      final sw = Stopwatch()..start();
      final topN = withHaversine.take(n).toList();

      RouteResult? bestRoute;
      Map<String, dynamic>? bestPoint;

      for (final p in topN) {
        final pLat = (p['latitude'] as num).toDouble();
        final pLon = (p['longitude'] as num).toDouble();
        final route = router.route(
          originLat: originLat,
          originLon: originLon,
          destinationLat: pLat,
          destinationLon: pLon,
          snapThresholdMeters: 50.0,
        );

        if (route.isSuccess) {
          if (bestRoute == null ||
              route.distanceMeters < bestRoute.distanceMeters) {
            bestRoute = route;
            bestPoint = p;
          }
        }
      }
      sw.stop();

      results.add(
        CandidateExperimentResult(
          candidateN: n,
          winningPointId: bestPoint?['water_point_id'] ?? 'NONE',
          winningDistrict: bestPoint?['district'] ?? 'UNKNOWN',
          walkingDistanceM: bestRoute?.distanceMeters ?? double.infinity,
          calculationTimeMs: sw.elapsedMicroseconds / 1000.0,
        ),
      );
    }

    return results;
  }
}
