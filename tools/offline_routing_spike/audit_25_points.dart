// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:aguacion_app/data/sources/local/routing/csr_graph.dart';
import 'package:aguacion_app/data/sources/local/routing/edge_spatial_grid.dart';

void main() async {
  final binFile = File('tools/offline_routing_spike/pedestrian_graph_lima_csr.bin');
  final ptsFile = File('assets/poc/data/water_points_normalized.json');

  final bytes = await binFile.readAsBytes();
  final graph = CsrGraph.fromBytes(bytes);
  final spatialGrid = EdgeSpatialGrid(graph);

  final ptsDecoded = json.decode(await ptsFile.readAsString());
  final waterPoints = ((ptsDecoded is Map ? ptsDecoded['records'] : ptsDecoded) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  print('Total points loaded: ${waterPoints.length}');

  final failed50m = <Map<String, dynamic>>[];

  for (final p in waterPoints) {
    final lat = (p['latitude'] as num).toDouble();
    final lon = (p['longitude'] as num).toDouble();

    final snap30 = spatialGrid.snapToSegment(lat, lon, thresholdMeters: 30.0);
    final snap50 = spatialGrid.snapToSegment(lat, lon, thresholdMeters: 50.0);
    final snap100 = spatialGrid.snapToSegment(lat, lon, thresholdMeters: 100.0);
    final snap500 = spatialGrid.snapToSegment(lat, lon, thresholdMeters: 500.0);

    if (!snap50.isSuccess) {
      failed50m.add({
        'water_point_id': p['water_point_id'],
        'source_fid': p['source_fid'],
        'official_code': p['official_code'],
        'component_type_raw': p['component_type_raw'],
        'eomr': p['eomr'],
        'department': p['department'],
        'province': p['province'],
        'district': p['district'],
        'district_ubigeo': p['district_ubigeo'],
        'location_description': p['location_description'],
        'latitude': lat,
        'longitude': lon,
        'snap_30m': snap30.isSuccess ? 'SNAP_OK' : 'SNAP_NOT_FOUND',
        'snap_50m': snap50.isSuccess ? 'SNAP_OK' : 'SNAP_NOT_FOUND',
        'snap_100m': snap100.isSuccess ? 'SNAP_OK' : 'SNAP_NOT_FOUND',
        'nearest_walkable_edge_distance_m': snap500.isSuccess ? double.parse(snap500.distanceMeters.toStringAsFixed(2)) : -1.0,
        'nearest_edge_id': snap500.isSuccess ? snap500.edgeId : -1,
        'nearest_edge_u': snap500.isSuccess ? snap500.uNodeIndex : -1,
        'nearest_edge_v': snap500.isSuccess ? snap500.vNodeIndex : -1,
        'nearest_edge_len_m': snap500.isSuccess ? double.parse(snap500.segmentLengthMeters.toStringAsFixed(2)) : -1.0,
      });
    }
  }

  print('Total points failed at 50m: ${failed50m.length}');
  final outJson = File('tools/offline_routing_spike/unconnected_25_points.json');
  await outJson.writeAsString(const JsonEncoder.withIndent('  ').convert(failed50m));
  print('Wrote ${outJson.path}');
}
