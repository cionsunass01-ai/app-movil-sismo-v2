
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:aguacion_app/data/sources/local/routing/csr_graph.dart';
import 'package:aguacion_app/data/sources/local/routing/edge_spatial_grid.dart';

void main() async {
  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  final graph = CsrGraph.fromBytes(await binFile.readAsBytes());
  final grid = EdgeSpatialGrid(graph);

  for (final th in [30.0, 50.0, 100.0, 130.0, 500.0]) {
    final s = grid.snapToSegment(-11.872467, -77.081309, thresholdMeters: th);
    print('Th: $th -> status: ${s.status}, dist: ${s.distanceMeters.toStringAsFixed(2)} m, edgeId: ${s.edgeId}');
  }
}
