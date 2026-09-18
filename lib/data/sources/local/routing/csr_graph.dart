import 'dart:convert';
import 'dart:typed_data';

class CsrGraph {
  final int nodeCount;
  final int undirectedEdgeCount;
  final int directedEdgeCount;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  final Int32List nodeLatsE6;
  final Int32List nodeLonsE6;
  final Uint32List nodeOffsets;
  final Uint32List edgeTargets;
  final Uint16List edgeWeightsDm;
  final Uint32List edgeIds;
  final Uint8List edgeFlags;

  CsrGraph._({
    required this.nodeCount,
    required this.undirectedEdgeCount,
    required this.directedEdgeCount,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.nodeLatsE6,
    required this.nodeLonsE6,
    required this.nodeOffsets,
    required this.edgeTargets,
    required this.edgeWeightsDm,
    required this.edgeIds,
    required this.edgeFlags,
  });

  factory CsrGraph.fromBytes(Uint8List bytes) {
    if (bytes.length < 64) {
      throw FormatException(
        'Buffer demasiado pequeño para cabecera CSR: ${bytes.length} B',
      );
    }

    final byteData = ByteData.sublistView(bytes);
    final magic = ascii.decode(bytes.sublist(0, 8));
    if (magic != 'AGUACSR1') {
      throw FormatException(
        'Identificador mágico inválido: $magic (esperado AGUACSR1)',
      );
    }

    final version = byteData.getUint32(8, Endian.little);
    if (version != 1) {
      throw FormatException('Versión no soportada de grafo CSR: $version');
    }

    final nodeCount = byteData.getUint32(24, Endian.little);
    final undirectedEdgeCount = byteData.getUint32(28, Endian.little);
    final directedEdgeCount = byteData.getUint32(32, Endian.little);

    final minLat = byteData.getInt32(36, Endian.little) / 1e6;
    final maxLat = byteData.getInt32(40, Endian.little) / 1e6;
    final minLon = byteData.getInt32(44, Endian.little) / 1e6;
    final maxLon = byteData.getInt32(48, Endian.little) / 1e6;

    int offset = 64;
    final nodeLats = Int32List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      nodeCount,
    );
    offset += nodeCount * 4;

    final nodeLons = Int32List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      nodeCount,
    );
    offset += nodeCount * 4;

    final nodeOffsets = Uint32List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      nodeCount + 1,
    );
    offset += (nodeCount + 1) * 4;

    final edgeTargets = Uint32List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      directedEdgeCount,
    );
    offset += directedEdgeCount * 4;

    final edgeWeights = Uint16List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      directedEdgeCount,
    );
    offset += directedEdgeCount * 2;

    final edgeIds = Uint32List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      directedEdgeCount,
    );
    offset += directedEdgeCount * 4;

    final edgeFlags = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes + offset,
      directedEdgeCount,
    );

    return CsrGraph._(
      nodeCount: nodeCount,
      undirectedEdgeCount: undirectedEdgeCount,
      directedEdgeCount: directedEdgeCount,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      nodeLatsE6: nodeLats,
      nodeLonsE6: nodeLons,
      nodeOffsets: nodeOffsets,
      edgeTargets: edgeTargets,
      edgeWeightsDm: edgeWeights,
      edgeIds: edgeIds,
      edgeFlags: edgeFlags,
    );
  }

  double getNodeLat(int u) => nodeLatsE6[u] / 1000000.0;
  double getNodeLon(int u) => nodeLonsE6[u] / 1000000.0;

  int getEdgeStart(int u) => nodeOffsets[u];
  int getEdgeEnd(int u) => nodeOffsets[u + 1];

  int getDegree(int u) => nodeOffsets[u + 1] - nodeOffsets[u];

  int getEdgeTarget(int edgeIndex) => edgeTargets[edgeIndex];
  double getEdgeWeightMeters(int edgeIndex) => edgeWeightsDm[edgeIndex] / 10.0;
  int getEdgeId(int edgeIndex) => edgeIds[edgeIndex];
  int getEdgeFlags(int edgeIndex) => edgeFlags[edgeIndex];
  bool isBridge(int edgeIndex) => (edgeFlags[edgeIndex] & 1) != 0;
}
