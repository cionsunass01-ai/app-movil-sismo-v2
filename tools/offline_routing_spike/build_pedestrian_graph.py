#!/usr/bin/env python3
"""
build_pedestrian_graph.py
Extracts a pedestrian routing graph for Lima & Callao from BBBike OSM data.
Calculates edge distances in meters, filters non-walkable ways, and exports
both JSON (compressed) and binary/SQLite formats for performance benchmarks.
"""

import gzip
import json
import math
import os
import sys
import time
from collections import defaultdict, deque
from lxml import etree

# Constants
EARTH_RADIUS_METERS = 6371000.0

WALKABLE_HIGHWAYS = {
    'footway', 'path', 'pedestrian', 'steps', 'living_street', 'corridor',
    'residential', 'service', 'unclassified',
    'tertiary', 'tertiary_link',
    'secondary', 'secondary_link',
    'primary', 'primary_link'
}

PROHIBITED_HIGHWAYS = {
    'motorway', 'motorway_link', 'construction', 'proposed', 'abandoned', 'raceway'
}

def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0)**2
    return 2.0 * EARTH_RADIUS_METERS * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

def build_graph(osm_gz_path: str, output_prefix: str):
    print(f"[{time.strftime('%X')}] Starting pedestrian graph construction from: {osm_gz_path}")
    t_start = time.time()

    # Pass 1: Parse ways and collect needed node IDs
    needed_nodes = set()
    walkable_ways = []
    total_ways = 0
    discarded_ways = 0

    print(f"[{time.strftime('%X')}] Pass 1: Filtering walkable ways...")
    with gzip.open(osm_gz_path, 'rb') as f:
        context = etree.iterparse(f, events=('end',), tag='way')
        for _, elem in context:
            total_ways += 1
            tags = {t.attrib['k']: t.attrib['v'] for t in elem.findall('tag')}
            hw = tags.get('highway')

            is_walkable = False
            if hw in WALKABLE_HIGHWAYS:
                is_walkable = True
            elif hw in ('trunk', 'trunk_link'):
                # In Lima, trunks can only be walked if explicitly designated with sidewalk
                sidewalk = tags.get('sidewalk', '')
                foot = tags.get('foot', '')
                if foot in ('yes', 'designated', 'permissive') or sidewalk in ('yes', 'both', 'left', 'right'):
                    is_walkable = True

            # Exclusions
            if tags.get('access') in ('no', 'private') or tags.get('foot') in ('no', 'private'):
                is_walkable = False
            if hw in PROHIBITED_HIGHWAYS:
                is_walkable = False

            if is_walkable:
                nd_refs = [int(nd.attrib['ref']) for nd in elem.findall('nd')]
                if len(nd_refs) >= 2:
                    is_bridge = tags.get('bridge') == 'yes'
                    name = tags.get('name', '')
                    walkable_ways.append({
                        'nodes': nd_refs,
                        'highway': hw,
                        'bridge': is_bridge,
                        'name': name
                    })
                    for ref in nd_refs:
                        needed_nodes.add(ref)
                else:
                    discarded_ways += 1
            else:
                discarded_ways += 1

            elem.clear()
            while elem.getprevious() is not None:
                del elem.getparent()[0]

    print(f"[{time.strftime('%X')}] Pass 1 complete in {time.time() - t_start:.2f}s.")
    print(f"  Total ways scanned: {total_ways}")
    print(f"  Walkable ways retained: {len(walkable_ways)}")
    print(f"  Distinct node references: {len(needed_nodes)}")

    # Pass 2: Extract coordinates for needed nodes
    t_pass2 = time.time()
    node_coords = {}
    print(f"[{time.strftime('%X')}] Pass 2: Extracting node coordinates...")
    with gzip.open(osm_gz_path, 'rb') as f:
        context = etree.iterparse(f, events=('end',), tag='node')
        for _, elem in context:
            nid = int(elem.attrib['id'])
            if nid in needed_nodes:
                node_coords[nid] = (round(float(elem.attrib['lat']), 7), round(float(elem.attrib['lon']), 7))
            elem.clear()
            while elem.getprevious() is not None:
                del elem.getparent()[0]

    print(f"[{time.strftime('%X')}] Pass 2 complete in {time.time() - t_pass2:.2f}s.")
    print(f"  Coordinates found for: {len(node_coords)} / {len(needed_nodes)} nodes.")

    # Pass 3: Construct Adjacency Graph
    t_pass3 = time.time()
    print(f"[{time.strftime('%X')}] Pass 3: Building adjacency graph...")
    adj = defaultdict(list)
    edge_count = 0
    bridge_edge_count = 0

    for way in walkable_ways:
        nds = way['nodes']
        hw = way['highway']
        is_bridge = way['bridge']
        name = way['name']

        for i in range(len(nds) - 1):
            u = nds[i]
            v = nds[i + 1]
            if u in node_coords and v in node_coords:
                lat1, lon1 = node_coords[u]
                lat2, lon2 = node_coords[v]
                dist = haversine_m(lat1, lon1, lat2, lon2)
                if dist > 0.01: # Avoid zero-length self-loops
                    # Add bidirectional edge
                    adj[u].append((v, round(dist, 2), hw, is_bridge, name))
                    adj[v].append((u, round(dist, 2), hw, is_bridge, name))
                    edge_count += 2
                    if is_bridge:
                        bridge_edge_count += 2

    active_nodes = set(adj.keys())
    print(f"[{time.strftime('%X')}] Graph constructed:")
    print(f"  Active nodes with edges: {len(active_nodes)}")
    print(f"  Directed edge entries (bidirectional): {edge_count}")
    print(f"  Bridge edge entries: {bridge_edge_count}")

    # Pass 4: Find connected components and isolate largest component
    print(f"[{time.strftime('%X')}] Pass 4: Analyzing graph connectivity...")
    visited = set()
    components = []
    for node in active_nodes:
        if node not in visited:
            comp = []
            queue = deque([node])
            visited.add(node)
            while queue:
                curr = queue.popleft()
                comp.append(curr)
                for neighbor, _, _, _, _ in adj[curr]:
                    if neighbor not in visited:
                        visited.add(neighbor)
                        queue.append(neighbor)
            components.append(comp)

    components.sort(key=len, reverse=True)
    largest_comp = set(components[0])
    print(f"  Total connected components: {len(components)}")
    print(f"  Largest component nodes: {len(largest_comp)} ({len(largest_comp)/len(active_nodes)*100:.2f}% of graph)")
    if len(components) > 1:
        print(f"  Second largest component: {len(components[1])} nodes")

    # Retain components with >= 10 nodes (main urban network + populated districts)
    usable_nodes = set()
    for comp in components:
        if len(comp) >= 10:
            usable_nodes.update(comp)

    pruned_node_coords = {nid: node_coords[nid] for nid in usable_nodes}
    pruned_adj = {}
    pruned_edge_count = 0
    for u in usable_nodes:
        pruned_adj[u] = []
        for v, dist, hw, is_bridge, name in adj[u]:
            if v in usable_nodes:
                pruned_adj[u].append((v, dist, hw, is_bridge, name))
                pruned_edge_count += 1

    print(f"[{time.strftime('%X')}] Final Pruned Graph:")
    print(f"  Nodes: {len(pruned_node_coords)}")
    print(f"  Directed Edges: {pruned_edge_count}")

    # Export to compressed JSON and uncompressed JSON
    json_path = f"{output_prefix}.json.gz"
    raw_json_path = f"{output_prefix}.json"
    print(f"[{time.strftime('%X')}] Exporting graph to: {json_path} and {raw_json_path}")

    nodes_export = [[nid, lat, lon] for nid, (lat, lon) in pruned_node_coords.items()]
    edges_export = []
    seen_edges = set()
    for u, neighbors in pruned_adj.items():
        for v, dist, hw, is_bridge, name in neighbors:
            edge_key = (min(u, v), max(u, v))
            if edge_key not in seen_edges:
                seen_edges.add(edge_key)
                edges_export.append([u, v, dist, hw, 1 if is_bridge else 0, name])

    graph_data = {
        'metadata': {
            'generated_at': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
            'source': os.path.basename(osm_gz_path),
            'nodes_count': len(nodes_export),
            'undirected_edges_count': len(edges_export),
            'directed_edges_count': pruned_edge_count,
            'bbox': [-77.26, -12.42, -76.56, -11.70]
        },
        'nodes': nodes_export,
        'edges': edges_export
    }

    with gzip.open(json_path, 'wt', encoding='utf-8') as f:
        json.dump(graph_data, f)

    with open(raw_json_path, 'w', encoding='utf-8') as f:
        json.dump(graph_data, f)

    t_end = time.time()
    raw_size_mb = os.path.getsize(raw_json_path) / (1024 * 1024)
    gz_size_mb = os.path.getsize(json_path) / (1024 * 1024)

    print(f"[{time.strftime('%X')}] Build complete in {t_end - t_start:.2f}s!")
    print(f"  Uncompressed JSON size: {raw_size_mb:.2f} MB")
    print(f"  Compressed JSON.GZ size: {gz_size_mb:.2f} MB")

    return {
        'nodes_count': len(nodes_export),
        'edges_count': len(edges_export),
        'directed_edges_count': pruned_edge_count,
        'raw_size_mb': raw_size_mb,
        'gz_size_mb': gz_size_mb,
        'json_gz_path': json_path,
        'raw_json_path': raw_json_path
    }

if __name__ == '__main__':
    osm_path = 'tools/offline_routing_spike/raw/Lima.osm.gz'
    out_prefix = 'tools/offline_routing_spike/pedestrian_graph_lima'
    build_graph(osm_path, out_prefix)
