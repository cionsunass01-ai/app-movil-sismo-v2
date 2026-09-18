
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:aguacion_app/data/sources/local/routing/csr_graph.dart';
import 'package:aguacion_app/data/sources/local/routing/edge_spatial_grid.dart';

void main() async {
  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  final graph = CsrGraph.fromBytes(await binFile.readAsBytes());
  final ptsFile = File('assets/poc/data/water_points_normalized.json');
  final ptsDecoded = json.decode(await ptsFile.readAsString());
  final waterPoints = ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final grid = EdgeSpatialGrid(graph);

  // Let's test each of the 433 points with threshold 50.0 and threshold 100.0
  int countFailed50 = 0;
  int countFailed100 = 0;
  for (final p in waterPoints) {
    final lat = (p['latitude'] as num).toDouble();
    final lon = (p['longitude'] as num).toDouble();
    final s50 = grid.snapToSegment(lat, lon, thresholdMeters: 50.0);
    final s100 = grid.snapToSegment(lat, lon, thresholdMeters: 100.0);
    if (!s50.isSuccess) countFailed50++;
    if (!s100.isSuccess) countFailed100++;
  }
  print('Failed at 50m: $countFailed50');
  print('Failed at 100m: $countFailed100');
}
