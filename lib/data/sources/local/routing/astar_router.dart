import '../../../../domain/routing/models/route_result.dart';
import 'csr_graph.dart';
import 'edge_spatial_grid.dart';

class _HeapNode implements Comparable<_HeapNode> {
  final double fScore;
  final double gScore;
  final int u;

  _HeapNode(this.fScore, this.gScore, this.u);

  @override
  int compareTo(_HeapNode other) => fScore.compareTo(other.fScore);
}

class _FastMinHeap {
  final List<_HeapNode> _data = [];

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  int get length => _data.length;

  void push(_HeapNode node) {
    _data.add(node);
    _siftUp(_data.length - 1);
  }

  _HeapNode pop() {
    final top = _data[0];
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _siftDown(0);
    }
    return top;
  }

  void _siftUp(int i) {
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_data[i].compareTo(_data[parent]) < 0) {
        final tmp = _data[i];
        _data[i] = _data[parent];
        _data[parent] = tmp;
        i = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int i) {
    final len = _data.length;
    while (true) {
      final left = (i << 1) + 1;
      final right = left + 1;
      int smallest = i;

      if (left < len && _data[left].compareTo(_data[smallest]) < 0) {
        smallest = left;
      }
      if (right < len && _data[right].compareTo(_data[smallest]) < 0) {
        smallest = right;
      }
      if (smallest != i) {
        final tmp = _data[i];
        _data[i] = _data[smallest];
        _data[smallest] = tmp;
        i = smallest;
      } else {
        break;
      }
    }
  }
}

class AstarRouter {
  final CsrGraph graph;
  final EdgeSpatialGrid spatialGrid;

  AstarRouter({required this.graph, required this.spatialGrid});

  /// Computes the shortest walkable pedestrian route between origin and destination.
  RouteResult route({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
    double snapThresholdMeters = 50.0,
    Set<int>? blockedEdgeIds,
  }) {
    final stopwatch = Stopwatch()..start();
    final blocked = blockedEdgeIds ?? const <int>{};

    // 1. Snap origin to walkable edge
    final snapOrigin = spatialGrid.snapToSegment(
      originLat,
      originLon,
      thresholdMeters: snapThresholdMeters,
    );
    if (!snapOrigin.isSuccess) {
      return RouteResult.failed(
        status: RouteStatus.originSnapFailed,
        message:
            'No se encontró vía peatonal accesible cerca del origen (umbral: ${snapThresholdMeters.toStringAsFixed(0)} m)',
        calculationTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }

    // 2. Snap destination to walkable edge
    final snapDest = spatialGrid.snapToSegment(
      destinationLat,
      destinationLon,
      thresholdMeters: snapThresholdMeters,
    );
    if (!snapDest.isSuccess) {
      return RouteResult.failed(
        status: RouteStatus.destinationSnapFailed,
        message:
            'No se encontró vía peatonal accesible cerca del punto de agua (umbral: ${snapThresholdMeters.toStringAsFixed(0)} m)',
        calculationTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }

    // Target virtual start & goal nodes:
    // Snapped point X on segment uOrig <-> vOrig
    final uOrig = snapOrigin.uNodeIndex;
    final vOrig = snapOrigin.vNodeIndex;
    final tOrig = snapOrigin.projectionT;
    final lOrig = snapOrigin.segmentLengthMeters;
    final distOriginToU = snapOrigin.distanceToU;
    final distOriginToV = snapOrigin.distanceToV;

    // Snapped point Y on segment uDest <-> vDest
    final uDest = snapDest.uNodeIndex;
    final vDest = snapDest.vNodeIndex;
    final tDest = snapDest.projectionT;
    final distDestToU = snapDest.distanceToU;
    final distDestToV = snapDest.distanceToV;

    final destSnappedLat = snapDest.snappedLat;
    final destSnappedLon = snapDest.snappedLon;

    // Check if origin and destination project onto the same street segment:
    final bool isSameSegment =
        (uOrig == uDest && vOrig == vDest) ||
        (uOrig == vDest && vOrig == uDest);
    double bestNetworkDistToY = double.infinity;
    int bestTargetExitNode =
        -1; // -2 for direct along same segment, or uDest / vDest

    if (isSameSegment && !blocked.contains(snapOrigin.edgeId)) {
      final double directTDist;
      if (uOrig == uDest) {
        directTDist = (tOrig - tDest).abs() * lOrig;
      } else {
        directTDist = (tOrig - (1.0 - tDest)).abs() * lOrig;
      }
      bestNetworkDistToY = directTDist;
      bestTargetExitNode = -2;
    }

    // 3. A* Search from virtual origin X
    final gScore = <int, double>{};
    final cameFromNode = <int, int>{};
    final cameFromEdgeId = <int, int>{};
    final visited = <int>{};
    final openSet = _FastMinHeap();

    double hToTarget(int node) {
      return EdgeSpatialGrid.haversineMeters(
        graph.getNodeLat(node),
        graph.getNodeLon(node),
        destSnappedLat,
        destSnappedLon,
      );
    }

    // Inject start endpoints from virtual origin X:
    if (uOrig != -1 && !blocked.contains(snapOrigin.edgeId)) {
      gScore[uOrig] = distOriginToU;
      cameFromNode[uOrig] = -1;
      cameFromEdgeId[uOrig] = snapOrigin.edgeId;
      openSet.push(
        _HeapNode(distOriginToU + hToTarget(uOrig), distOriginToU, uOrig),
      );

      if (vOrig != uOrig && vOrig != -1) {
        gScore[vOrig] = distOriginToV;
        cameFromNode[vOrig] = -1;
        cameFromEdgeId[vOrig] = snapOrigin.edgeId;
        openSet.push(
          _HeapNode(distOriginToV + hToTarget(vOrig), distOriginToV, vOrig),
        );
      }
    }

    int exploredCount = 0;

    while (openSet.isNotEmpty) {
      final current = openSet.pop();
      final u = current.u;

      // Admissible early-stopping: no remaining path in openSet can beat bestNetworkDistToY
      if (current.fScore >= bestNetworkDistToY) {
        break;
      }

      if (!visited.add(u)) continue;
      exploredCount++;

      final dCurr = current.gScore;

      // Check exit to destination via uDest or vDest
      if (u == uDest) {
        final totalViaU = dCurr + distDestToU;
        if (totalViaU < bestNetworkDistToY) {
          bestNetworkDistToY = totalViaU;
          bestTargetExitNode = uDest;
        }
      }
      if (u == vDest) {
        final totalViaV = dCurr + distDestToV;
        if (totalViaV < bestNetworkDistToY) {
          bestNetworkDistToY = totalViaV;
          bestTargetExitNode = vDest;
        }
      }

      final startEdge = graph.getEdgeStart(u);
      final endEdge = graph.getEdgeEnd(u);

      for (int i = startEdge; i < endEdge; i++) {
        final edgeId = graph.getEdgeId(i);
        if (blocked.contains(edgeId)) continue; // Dynamic edge exclusion

        final v = graph.getEdgeTarget(i);
        if (visited.contains(v)) continue;

        final weight = graph.getEdgeWeightMeters(i);
        final tentativeG = dCurr + weight;

        final existingG = gScore[v] ?? double.infinity;
        if (tentativeG < existingG) {
          gScore[v] = tentativeG;
          cameFromNode[v] = u;
          cameFromEdgeId[v] = edgeId;

          final h = hToTarget(v);
          openSet.push(_HeapNode(tentativeG + h, tentativeG, v));
        }
      }
    }

    stopwatch.stop();
    final calcMs = stopwatch.elapsedMicroseconds / 1000.0;

    if (bestTargetExitNode == -1) {
      return RouteResult.failed(
        status: RouteStatus.unreachable,
        message:
            'No existe ruta peatonal transitable entre el origen y el destino seleccionado según el grafo disponible.',
        calculationTimeMs: calcMs,
        visitedNodes: exploredCount,
      );
    }

    // 4. Path reconstruction
    final pathNodes = <int>[];
    final pathEdges = <int>[];

    if (bestTargetExitNode == -2) {
      pathEdges.add(snapOrigin.edgeId);
      pathNodes.add(uOrig);
      if (vOrig != uOrig) pathNodes.add(vOrig);
    } else {
      int curr = bestTargetExitNode;
      while (curr != -1) {
        pathNodes.add(curr);
        final parent = cameFromNode[curr];
        if (parent == null) break;
        if (parent != -1) {
          final edgeId = cameFromEdgeId[curr];
          if (edgeId != null) pathEdges.add(edgeId);
        }
        curr = parent;
      }
    }

    final reversedNodes = (bestTargetExitNode == -2)
        ? pathNodes
        : pathNodes.reversed.toList();
    final reversedEdges = (bestTargetExitNode == -2)
        ? pathEdges
        : pathEdges.reversed.toList();

    // Coordinates: User -> Snapped Origin -> Street Graph -> Snapped Dest -> Destination
    final polyline = <List<double>>[];
    polyline.add([originLon, originLat]);

    void addCoord(double lon, double lat) {
      if (polyline.isNotEmpty) {
        final last = polyline.last;
        final dLon = (last[0] - lon).abs();
        final dLat = (last[1] - lat).abs();
        if (dLon < 1e-7 && dLat < 1e-7) {
          return; // avoid duplicate consecutive vertices
        }
      }
      polyline.add([lon, lat]);
    }

    addCoord(snapOrigin.snappedLon, snapOrigin.snappedLat);

    if (bestTargetExitNode != -2) {
      for (final nodeIdx in reversedNodes) {
        addCoord(graph.getNodeLon(nodeIdx), graph.getNodeLat(nodeIdx));
      }
    }

    addCoord(snapDest.snappedLon, snapDest.snappedLat);
    addCoord(destinationLon, destinationLat);

    final totalDist =
        snapOrigin.distanceMeters +
        bestNetworkDistToY +
        snapDest.distanceMeters;

    final durationMin = totalDist / 67.0; // 4 km/h ~ 67 m/min

    return RouteResult(
      status: RouteStatus.success,
      distanceMeters: totalDist,
      durationMinutes: durationMin,
      calculationTimeMs: calcMs,
      visitedNodes: exploredCount,
      polylineCoords: polyline,
      pathNodeIndices: reversedNodes,
      pathEdgeIds: reversedEdges,
      originSnapDistance: snapOrigin.distanceMeters,
      destinationSnapDistance: snapDest.distanceMeters,
      blockedEdgesCount: blocked.length,
    );
  }
}
