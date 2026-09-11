
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:aguacion_app/poc/offline_navigation/graph/csr_graph.dart';
import 'package:aguacion_app/poc/offline_navigation/spatial/edge_spatial_grid.dart';

void main() async {
  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  final graph = CsrGraph.fromBytes(await binFile.readAsBytes());
  final ptsFile = File('assets/poc/data/water_points_normalized.json');
  final ptsDecoded = json.decode(await ptsFile.readAsString());
  final waterPoints = ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final grid = EdgeSpatialGrid(graph);

  print('Puntos que fallan a 100m:');
  for (final p in waterPoints) {
    final lat = (p['latitude'] as num).toDouble();
    final lon = (p['longitude'] as num).toDouble();
    final s100 = grid.snapToSegment(lat, lon, thresholdMeters: 100.0);
    if (!s100.isSuccess) {
      print('FID ${p["source_fid"]}: ${p["official_code"]} | ${p["district"]} | ${p["component_type_raw"]} | coords: ($lat, $lon)');
    }
  }
}
