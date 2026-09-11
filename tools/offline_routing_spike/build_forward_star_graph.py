#!/usr/bin/env python3
"""
build_forward_star_graph.py
Converts pedestrian_graph_lima.json into a highly optimized CSR (Compressed Sparse Row)
binary format for high-speed, zero-GC Dart parsing:

Header Layout (64 bytes):
  - magic (8 bytes): "AGUACSR1"
  - version (uint32): 1
  - reserved0 (uint32): 0
  - dataset_hash (8 bytes): SHA-256 prefix
  - node_count (uint32)
  - edge_count_undirected (uint32)
  - edge_count_directed (uint32)
  - min_lat_e6 (int32 microdegrees)
  - max_lat_e6 (int32 microdegrees)
  - min_lon_e6 (int32 microdegrees)
  - max_lon_e6 (int32 microdegrees)
  - reserved (12 bytes padding)

Data Sections:
  1. node_lats: node_count * int32 (microdegrees, lat * 1e6)
  2. node_lons: node_count * int32 (microdegrees, lon * 1e6)
  3. node_offsets: (node_count + 1) * uint32 (indices into edge arrays)
  4. edge_targets: edge_count_directed * uint32 (neighbor node index)
  5. edge_weights: edge_count_directed * uint16 (distance in decimeters: 0.1m units)
  6. edge_ids: edge_count_directed * uint32 (undirected edge id for dynamic blocking)
  7. edge_flags: edge_count_directed * uint8 (bit 0: bridge, bit 1: footway/path, bit 2: steps, etc.)
"""

import gzip
import json
import os
import struct
import sys
import time
import hashlib

def build_csr():
    json_path = 'tools/offline_routing_spike/pedestrian_graph_lima.json.gz'
    if not os.path.exists(json_path):
        json_path = 'tools/offline_routing_spike/pedestrian_graph_lima.json'

    print(f"Loading graph from {json_path}...")
    t0 = time.time()
    if json_path.endswith('.gz'):
        with gzip.open(json_path, 'rt', encoding='utf-8') as f:
            data = json.load(f)
    else:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    print(f"Loaded JSON in {time.time()-t0:.2f}s")

    raw_nodes = data['nodes'] # [nid, lat, lon]
    raw_edges = data['edges'] # [u, v, dist, hw, is_bridge, name]

    node_count = len(raw_nodes)
    undirected_edge_count = len(raw_edges)
    print(f"Raw nodes: {node_count}, Undirected edges: {undirected_edge_count}")

    # Map OSM node IDs to sequential index 0 .. node_count - 1
    id_map = {node[0]: i for i, node in enumerate(raw_nodes)}

    # Pre-allocate adjacency list for CSR
    adj = [[] for _ in range(node_count)]

    for edge_id, e in enumerate(raw_edges):
        u_osm, v_osm, dist_m, hw, is_bridge = e[0], e[1], e[2], e[3], e[4]
        if u_osm not in id_map or v_osm not in id_map:
            continue
        u = id_map[u_osm]
        v = id_map[v_osm]

        # Flags
        flags = 0
        if is_bridge:
            flags |= 1
        if hw in ('footway', 'path', 'pedestrian'):
            flags |= 2
        if hw == 'steps':
            flags |= 4

        dist_dm = min(65535, int(round(dist_m * 10))) # decimeters

        # Bidirectional edges in CSR
        adj[u].append((v, dist_dm, edge_id, flags))
        adj[v].append((u, dist_dm, edge_id, flags))

    directed_edge_count = sum(len(neighbors) for neighbors in adj)
    print(f"Directed edge entries: {directed_edge_count}")

    # Bounding box & coordinates in microdegrees
    min_lat_e6 = int(round(min(n[1] for n in raw_nodes) * 1e6))
    max_lat_e6 = int(round(max(n[1] for n in raw_nodes) * 1e6))
    min_lon_e6 = int(round(min(n[2] for n in raw_nodes) * 1e6))
    max_lon_e6 = int(round(max(n[2] for n in raw_nodes) * 1e6))

    out_bin_path = 'tools/offline_routing_spike/pedestrian_graph_lima_csr.bin'
    print(f"Writing CSR binary to {out_bin_path}...")
    t_write = time.time()

    with open(out_bin_path, 'wb') as f:
        # Header (64 bytes)
        magic = b'AGUACSR1'
        version = 1
        dataset_hash = hashlib.sha256(json_path.encode()).digest()[:8]
        header = struct.pack(
            '<8sII8sIIIiiii12s',
            magic,
            version,
            0, # padding
            dataset_hash,
            node_count,
            undirected_edge_count,
            directed_edge_count,
            min_lat_e6,
            max_lat_e6,
            min_lon_e6,
            max_lon_e6,
            b'\x00' * 12
        )
        assert len(header) == 64, f"Header length must be 64 bytes, got {len(header)}"
        f.write(header)

        # 1. node_lats (int32 microdegrees)
        f.write(struct.pack(f'<{node_count}i', *(int(round(n[1] * 1e6)) for n in raw_nodes)))

        # 2. node_lons (int32 microdegrees)
        f.write(struct.pack(f'<{node_count}i', *(int(round(n[2] * 1e6)) for n in raw_nodes)))

        # 3. node_offsets ((node_count + 1) * uint32)
        offsets = []
        offset = 0
        for neighbors in adj:
            offsets.append(offset)
            offset += len(neighbors)
        offsets.append(offset)
        assert offset == directed_edge_count
        f.write(struct.pack(f'<{len(offsets)}I', *offsets))

        # Flatten edge data for batch writing
        edge_targets = []
        edge_weights = []
        edge_ids = []
        edge_flags = []
        for neighbors in adj:
            for v, dist_dm, edge_id, flags in neighbors:
                edge_targets.append(v)
                edge_weights.append(dist_dm)
                edge_ids.append(edge_id)
                edge_flags.append(flags)

        # 4. edge_targets (directed_edge_count * uint32)
        f.write(struct.pack(f'<{directed_edge_count}I', *edge_targets))

        # 5. edge_weights (directed_edge_count * uint16 decimeters)
        f.write(struct.pack(f'<{directed_edge_count}H', *edge_weights))

        # 6. edge_ids (directed_edge_count * uint32)
        f.write(struct.pack(f'<{directed_edge_count}I', *edge_ids))

        # 7. edge_flags (directed_edge_count * uint8)
        f.write(struct.pack(f'<{directed_edge_count}B', *edge_flags))

    raw_size = os.path.getsize(out_bin_path)
    print(f"CSR binary written in {time.time()-t_write:.2f}s: {raw_size:,} bytes ({raw_size/(1024*1024):.2f} MB)")

    # Compress with gzip
    out_gz_path = out_bin_path + '.gz'
    print(f"Compressing to {out_gz_path}...")
    t_gz = time.time()
    with open(out_bin_path, 'rb') as f_in, gzip.open(out_gz_path, 'wb') as f_out:
        f_out.writelines(f_in)

    gz_size = os.path.getsize(out_gz_path)
    print(f"CSR compressed binary in {time.time()-t_gz:.2f}s: {gz_size:,} bytes ({gz_size/(1024*1024):.2f} MB)")

if __name__ == '__main__':
    build_csr()
