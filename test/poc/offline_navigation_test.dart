import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aguacion_app/poc/offline_navigation/graph/csr_graph.dart';
import 'package:aguacion_app/poc/offline_navigation/spatial/edge_spatial_grid.dart';
import 'package:aguacion_app/poc/offline_navigation/routing/astar_router.dart';
import 'package:aguacion_app/poc/offline_navigation/routing/adaptive_water_point_search.dart';
import 'package:aguacion_app/poc/offline_navigation/models/snap_result.dart';
import 'package:aguacion_app/poc/offline_navigation/models/route_result.dart';

void main() {
  group('Offline Navigation POC Core Engine Tests', () {
    late CsrGraph graph;
    late EdgeSpatialGrid spatialGrid;
    late AstarRouter router;

    setUpAll(() async {
      final binFile = File(
        'tools/offline_routing_spike/pedestrian_graph_lima_csr.bin',
      );
      expect(
        binFile.existsSync(),
        isTrue,
        reason: 'CSR binary file must exist on disk',
      );

      final bytes = await binFile.readAsBytes();
      graph = CsrGraph.fromBytes(bytes);
      spatialGrid = EdgeSpatialGrid(graph);
      router = AstarRouter(graph: graph, spatialGrid: spatialGrid);
    });

    test('1. CSR Graph parses header and coordinates correctly', () {
      expect(graph.nodeCount, equals(855857));
      expect(graph.directedEdgeCount, equals(1990320));
      expect(graph.minLat, lessThan(-12.0));
      expect(graph.maxLat, greaterThan(-12.0));
      expect(graph.minLon, lessThan(-77.0));
      expect(graph.maxLon, greaterThan(-77.0));
    });

    test(
      '2. Snapping projects to segment and respects conservative thresholds',
      () {
        // Regular street in Lima Centro
        final snapOk = spatialGrid.snapToSegment(
          -12.0440,
          -77.0280,
          thresholdMeters: 50.0,
        );
        expect(snapOk.isSuccess, isTrue);
        expect(snapOk.distanceMeters, lessThan(30.0));
        expect(snapOk.edgeId, greaterThanOrEqualTo(0));
        expect(snapOk.projectionT, inInclusiveRange(0.0, 1.0));

        // Point in Pacific Ocean (outside network)
        final snapOcean = spatialGrid.snapToSegment(
          -12.0800,
          -77.2000,
          thresholdMeters: 50.0,
        );
        expect(snapOcean.status, equals(SnapStatus.snapNotFound));
        expect(snapOcean.isSuccess, isFalse);
      },
    );

    test('3. A* calculates real pedestrian route with valid polyline', () {
      final result = router.route(
        originLat: -12.0453,
        originLon: -77.0311, // Plaza Mayor
        destinationLat: -12.0440,
        destinationLon: -77.0345, // Santo Domingo
        snapThresholdMeters: 50.0,
      );

      expect(result.status, equals(RouteStatus.success));
      expect(result.distanceMeters, inInclusiveRange(300.0, 800.0));
      expect(result.visitedNodes, greaterThan(10));
      expect(result.polylineCoords.length, greaterThan(5));
      expect(result.pathNodeIndices.isNotEmpty, isTrue);
    });

    test(
      '4. Dynamic Edge Blocking reroutes and calculates positive detour delta',
      () {
        final base = router.route(
          originLat: -12.0440,
          originLon: -77.0280,
          destinationLat: -12.0390,
          destinationLon: -77.0270,
          snapThresholdMeters: 50.0,
        );
        expect(base.isSuccess, isTrue);

        final middleEdge = base.pathEdgeIds[base.pathEdgeIds.length ~/ 2];
        final detour = router.route(
          originLat: -12.0440,
          originLon: -77.0280,
          destinationLat: -12.0390,
          destinationLon: -77.0270,
          snapThresholdMeters: 50.0,
          blockedEdgeIds: {middleEdge},
        );

        expect(detour.isSuccess, isTrue);
        expect(
          detour.distanceMeters,
          greaterThanOrEqualTo(base.distanceMeters),
        );
        expect(detour.blockedEdgesCount, equals(1));
      },
    );

    test(
      '5. Snapping accurately computes segmentLengthMeters and partial traversal costs',
      () {
        final snap = spatialGrid.snapToSegment(
          -12.0450,
          -77.0300,
          thresholdMeters: 50.0,
        );
        expect(snap.isSuccess, isTrue);
        expect(snap.segmentLengthMeters, greaterThan(0.0));
        expect(snap.projectionT, inInclusiveRange(0.0, 1.0));
        expect(
          snap.distanceToU + snap.distanceToV,
          closeTo(snap.segmentLengthMeters, 0.001),
        );
      },
    );

    test('6. Snapping handles spatial edge cases appropriately', () {
      // Near highway: Panamericana Norte (-11.9800, -77.0600)
      final snapHighway = spatialGrid.snapToSegment(
        -11.9800,
        -77.0600,
        thresholdMeters: 50.0,
      );
      expect(snapHighway.isSuccess, isTrue);

      // Deep in the ocean (> 10 km offshore): must be snapNotFound
      final snapOcean = spatialGrid.snapToSegment(
        -12.1500,
        -77.2500,
        thresholdMeters: 50.0,
      );
      expect(snapOcean.status, equals(SnapStatus.snapNotFound));

      // Middle of Campo de Marte park lawn:
      final snapPark = spatialGrid.snapToSegment(
        -12.0680,
        -77.0420,
        thresholdMeters: 50.0,
      );
      if (snapPark.isSuccess) {
        expect(snapPark.distanceMeters, lessThanOrEqualTo(50.0));
      } else {
        expect(snapPark.status, equals(SnapStatus.snapNotFound));
      }

      // Conservative threshold test: 30m vs 50m vs 100m
      // Regular street near Plaza (-12.0440, -77.0280) is ~12m away -> connects on 30m, 50m, 100m
      final snapClose30 = spatialGrid.snapToSegment(
        -12.0440,
        -77.0280,
        thresholdMeters: 30.0,
      );
      expect(snapClose30.isSuccess, isTrue);

      // Intermediate point (-12.0450, -77.0300) is ~35m away:
      // Rejected by 30m threshold, but successfully connects on 50m and 100m
      final snapMid30 = spatialGrid.snapToSegment(
        -12.0450,
        -77.0300,
        thresholdMeters: 30.0,
      );
      final snapMid50 = spatialGrid.snapToSegment(
        -12.0450,
        -77.0300,
        thresholdMeters: 50.0,
      );
      final snapMid100 = spatialGrid.snapToSegment(
        -12.0450,
        -77.0300,
        thresholdMeters: 100.0,
      );
      expect(snapMid30.status, equals(SnapStatus.snapNotFound));
      expect(snapMid50.isSuccess, isTrue);
      expect(snapMid100.isSuccess, isTrue);
    });

    test(
      '7. AdaptiveWaterPointSearch matches Exhaustive Oracle across diverse Lima-Callao zones',
      () async {
        final ptsStr = await File(
          'assets/poc/data/water_points_normalized.json',
        ).readAsString();
        final ptsDecoded = json.decode(ptsStr);
        final waterPoints =
            ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded)
                    as List<dynamic>)
                .cast<Map<String, dynamic>>();

        final adaptiveSearch = AdaptiveWaterPointSearch(router);

        final testOrigins = [
          {'name': 'Lima Norte (Los Olivos)', 'lat': -11.9750, 'lon': -77.0650},
          {
            'name': 'Lima Centro (Plaza Mayor)',
            'lat': -12.0453,
            'lon': -77.0311,
          },
          {
            'name': 'Lima Este (Ate / Vitarte)',
            'lat': -12.0250,
            'lon': -76.9200,
          },
          {
            'name': 'Lima Sur (Miraflores / Barranco)',
            'lat': -12.1350,
            'lon': -77.0200,
          },
          {
            'name': 'Callao (La Punta / Puerto)',
            'lat': -12.0600,
            'lon': -77.1400,
          },
        ];

        for (final orig in testOrigins) {
          final oLat = orig['lat'] as double;
          final oLon = orig['lon'] as double;

          final adaptiveResult = adaptiveSearch.search(
            originLat: oLat,
            originLon: oLon,
            waterPoints: waterPoints,
            snapThresholdMeters: 50.0,
          );

          expect(
            adaptiveResult.winnerPoint,
            isNotNull,
            reason: 'Must find winner in ${orig['name']}',
          );
          expect(adaptiveResult.winnerRoute, isNotNull);
          expect(adaptiveResult.winnerRoute!.isSuccess, isTrue);
          expect(
            adaptiveResult.candidatesRoutedCount,
            lessThanOrEqualTo(waterPoints.length),
          );
          expect(adaptiveResult.candidatesRoutedCount, greaterThan(0));

          // Compare against top 20 exhaustive oracle for strict verification
          final top20Candidates =
              waterPoints.map((p) {
                final lat = (p['latitude'] as num).toDouble();
                final lon = (p['longitude'] as num).toDouble();
                final h = EdgeSpatialGrid.haversineMeters(oLat, oLon, lat, lon);
                return {'point': p, 'h': h};
              }).toList()..sort(
                (a, b) => (a['h'] as double).compareTo(b['h'] as double),
              );

          double oracleMinDist = double.infinity;
          String? oracleWinnerId;
          for (final c in top20Candidates.take(20)) {
            final p = c['point'] as Map<String, dynamic>;
            final r = router.route(
              originLat: oLat,
              originLon: oLon,
              destinationLat: (p['latitude'] as num).toDouble(),
              destinationLon: (p['longitude'] as num).toDouble(),
              snapThresholdMeters: 50.0,
            );
            if (r.isSuccess && r.distanceMeters < oracleMinDist) {
              oracleMinDist = r.distanceMeters;
              oracleWinnerId = p['water_point_id'] as String;
            }
          }

          expect(
            adaptiveResult.winnerPoint!['water_point_id'],
            equals(oracleWinnerId),
            reason:
                'Adaptive search must find the exact same winner as the exhaustive oracle in ${orig['name']}',
          );
          expect(
            adaptiveResult.winnerRoute!.distanceMeters,
            closeTo(oracleMinDist, 0.01),
          );
        }
      },
    );

    test(
      '8. Offline Style and Local Glyphs Audit (Zero HTTP/HTTPS, Full Spanish Support)',
      () async {
        final styleFile = File(
          'assets/poc/styles/emergency_geometric_style.json',
        );
        expect(styleFile.existsSync(), isTrue);

        final styleRaw = await styleFile.readAsString();
        expect(
          styleRaw.contains('http://'),
          isFalse,
          reason: 'Zero http:// in style JSON',
        );
        expect(
          styleRaw.contains('https://'),
          isFalse,
          reason: 'Zero https:// in style JSON',
        );

        final styleJson = json.decode(styleRaw) as Map<String, dynamic>;
        expect(styleJson['glyphs'], isNotNull);
        expect(
          (styleJson['glyphs'] as String).contains('{fontstack}/{range}.pbf'),
          isTrue,
        );

        final layers = styleJson['layers'] as List<dynamic>;
        final symbolLayers = layers
            .where((l) => l['type'] == 'symbol')
            .toList();
        expect(
          symbolLayers.length,
          greaterThanOrEqualTo(4),
          reason: 'Must contain places, water, major and minor road labels',
        );

        final layerIds = symbolLayers.map((l) => l['id'] as String).toList();
        expect(
          layerIds,
          containsAll([
            'places_labels',
            'water_labels',
            'roads_major_labels',
            'roads_minor_labels',
          ]),
        );

        // Verify font PBF files exist in assets
        final requiredFonts = [
          'assets/poc/fonts/Noto Sans Regular/0-255.pbf',
          'assets/poc/fonts/Noto Sans Regular/256-511.pbf',
          'assets/poc/fonts/Noto Sans Bold/0-255.pbf',
          'assets/poc/fonts/Noto Sans Bold/256-511.pbf',
        ];
        for (final fontPath in requiredFonts) {
          final f = File(fontPath);
          expect(
            f.existsSync(),
            isTrue,
            reason: 'Font file must exist: $fontPath',
          );
          expect(
            f.lengthSync(),
            greaterThan(10000),
            reason: 'Font file must have non-trivial size',
          );
        }
      },
    );
  });
}
