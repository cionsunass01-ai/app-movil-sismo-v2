#!/usr/bin/env python3
"""
export_graph_formats.py
Converts pedestrian_graph_lima.json into:
1. SQLite database with spatial indexes
2. Flat binary format (packed struct)
Measures exact disk sizes and loading benchmarks.
"""

import gzip
import json
import os
import sqlite3
import struct
import time

def convert():
    json_path = 'tools/offline_routing_spike/pedestrian_graph_lima.json'
    print(f"Loading {json_path}...")
    t0 = time.time()
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"Loaded JSON in {time.time()-t0:.2f}s")

    nodes = data['nodes'] # [nid, lat, lon]
    edges = data['edges'] # [u, v, dist, hw, is_bridge, name]
    print(f"Nodes: {len(nodes)}, Edges: {len(edges)}")

    # 1. SQLite Database
    db_path = 'tools/offline_routing_spike/pedestrian_graph_lima.db'
    if os.path.exists(db_path):
        os.remove(db_path)

    print(f"Creating SQLite database: {db_path}...")
    t_db = time.time()
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("PRAGMA synchronous = OFF")
    cur.execute("PRAGMA journal_mode = MEMORY")

    cur.execute("CREATE TABLE nodes (id INTEGER PRIMARY KEY, lat REAL, lon REAL)")
    cur.execute("CREATE TABLE edges (u INTEGER, v INTEGER, dist REAL, hw TEXT, bridge INTEGER)")

    cur.executemany("INSERT INTO nodes VALUES (?, ?, ?)", nodes)
    cur.executemany("INSERT INTO edges VALUES (?, ?, ?, ?, ?)", [(e[0], e[1], e[2], e[3], e[4]) for e in edges])

    cur.execute("CREATE INDEX idx_edges_u ON edges(u)")
    cur.execute("CREATE INDEX idx_edges_v ON edges(v)")
    conn.commit()
    conn.close()
    print(f"SQLite created in {time.time()-t_db:.2f}s, size: {os.path.getsize(db_path)/(1024*1024):.2f} MB")

    # 2. Compact Flat Binary Format
    # Mapping node_id to sequential 0-indexed integer (uint32)
    bin_path = 'tools/offline_routing_spike/pedestrian_graph_lima.bin'
    print(f"Creating compact binary file: {bin_path}...")
    t_bin = time.time()

    id_map = {n[0]: i for i, n in enumerate(nodes)}

    with open(bin_path, 'wb') as f:
        # Header: magic(4B), num_nodes(uint32), num_edges(uint32)
        f.write(b'AGUA')
        f.write(struct.pack('<II', len(nodes), len(edges)))

        # Nodes: lat(float32), lon(float32), osm_id(uint64)
        for nid, lat, lon in nodes:
            f.write(struct.pack('<ffQ', lat, lon, nid))

        # Edges: u_idx(uint32), v_idx(uint32), dist_decimeters(uint16), bridge(uint8)
        for e in edges:
            u_idx = id_map.get(e[0], 0)
            v_idx = id_map.get(e[1], 0)
            dist_dm = min(65535, int(e[2] * 10)) # decimeters
            bridge = e[4]
            f.write(struct.pack('<IIHB', u_idx, v_idx, dist_dm, bridge))

    # Compress binary with gzip
    bin_gz_path = bin_path + '.gz'
    with open(bin_path, 'rb') as f_in, gzip.open(bin_gz_path, 'wb') as f_out:
        f_out.writelines(f_in)

    print(f"Binary created in {time.time()-t_bin:.2f}s")
    print(f"  Binary size: {os.path.getsize(bin_path)/(1024*1024):.2f} MB")
    print(f"  Binary GZ size: {os.path.getsize(bin_gz_path)/(1024*1024):.2f} MB")

if __name__ == '__main__':
    convert()
