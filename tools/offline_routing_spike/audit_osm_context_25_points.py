#!/usr/bin/env python3
"""
audit_osm_context_25_points.py
Audits the surrounding OpenStreetMap context for the 25 water points
that result in SNAP_NOT_FOUND at the 50m threshold.
"""

import gzip
import json
import math
import os
import sys
import time
from collections import defaultdict
from lxml import etree

EARTH_RADIUS_METERS = 6371000.0

def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0)**2
    return 2.0 * EARTH_RADIUS_METERS * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

def point_to_segment_dist_m(plat, plon, lat1, lon1, lat2, lon2):
    cos_lat = math.cos(math.radians(plat))
    mx = (lon2 - lon1) * 111320.0 * cos_lat
    my = (lat2 - lat1) * 110540.0
    px = (plon - lon1) * 111320.0 * cos_lat
    py = (plat - lat1) * 110540.0
    seg_len_sq = mx * mx + my * my
    if seg_len_sq < 0.0001:
        return haversine_m(plat, plon, lat1, lon1)
    t = (px * mx + py * my) / seg_len_sq
    t = max(0.0, min(1.0, t))
    proj_lat = lat1 + t * (lat2 - lat1)
    proj_lon = lon1 + t * (lon2 - lon1)
    return haversine_m(plat, plon, proj_lat, proj_lon)

def main():
    print(f"[{time.strftime('%X')}] Starting OSM Context Audit for 25 unconnected points...")

    with open('tools/offline_routing_spike/unconnected_25_points.json') as f:
        pts = json.load(f)
    print(f"Loaded {len(pts)} points to audit.")

    osm_gz_path = 'tools/offline_routing_spike/raw/Lima.osm.gz'

    # 1. First pass: find all OSM nodes within 400m bbox of any of the 25 points
    print(f"[{time.strftime('%X')}] Pass 1: Scanning OSM nodes within 400m...")
    target_nodes = {} # node_id -> (lat, lon, [pt_indices])

    # Precompute bboxes for 25 points (+- 0.004 deg approx 440m)
    bboxes = []
    for i, p in enumerate(pts):
        lat, lon = p['latitude'], p['longitude']
        bboxes.append({
            'index': i,
            'fid': p['source_fid'],
            'lat': lat,
            'lon': lon,
            'min_lat': lat - 0.004,
            'max_lat': lat + 0.004,
            'min_lon': lon - 0.004,
            'max_lon': lon + 0.004,
        })

    with gzip.open(osm_gz_path, 'rb') as f:
        context = etree.iterparse(f, events=('end',), tag='node')
        for _, elem in context:
            nid = int(elem.attrib['id'])
            nlat = float(elem.attrib['lat'])
            nlon = float(elem.attrib['lon'])

            matched = []
            for bb in bboxes:
                if bb['min_lat'] <= nlat <= bb['max_lat'] and bb['min_lon'] <= nlon <= bb['max_lon']:
                    d = haversine_m(bb['lat'], bb['lon'], nlat, nlon)
                    if d <= 400.0:
                        matched.append((bb['index'], d))

            if matched:
                target_nodes[nid] = (nlat, nlon, matched)

            elem.clear()
            while elem.getprevious() is not None:
                del elem.getparent()[0]

    print(f"[{time.strftime('%X')}] Pass 1 complete. Found {len(target_nodes)} OSM nodes near the 25 points.")

    # 2. Second pass: scan ways referencing any target nodes
    print(f"[{time.strftime('%X')}] Pass 2: Scanning OSM ways...")
    pt_ways = defaultdict(list) # pt_index -> list of nearby ways with metadata

    with gzip.open(osm_gz_path, 'rb') as f:
        context = etree.iterparse(f, events=('end',), tag='way')
        for _, elem in context:
            wid = int(elem.attrib['id'])
            nd_refs = [int(nd.attrib['ref']) for nd in elem.findall('nd')]

            # Check if any nd_ref is in target_nodes
            relevant_pts = set()
            for ref in nd_refs:
                if ref in target_nodes:
                    for pidx, _ in target_nodes[ref][2]:
                        relevant_pts.add(pidx)

            if relevant_pts:
                tags = {t.attrib['k']: t.attrib['v'] for t in elem.findall('tag')}
                # Reconstruct full or partial geometry of way
                way_coords = [target_nodes[r][:2] for r in nd_refs if r in target_nodes]

                if len(way_coords) >= 2:
                    for pidx in relevant_pts:
                        plat = pts[pidx]['latitude']
                        plon = pts[pidx]['longitude']

                        min_dist = float('inf')
                        for i in range(len(way_coords) - 1):
                            lat1, lon1 = way_coords[i]
                            lat2, lon2 = way_coords[i+1]
                            d = point_to_segment_dist_m(plat, plon, lat1, lon1, lat2, lon2)
                            if d < min_dist:
                                min_dist = d

                        if min_dist <= 350.0:
                            pt_ways[pidx].append({
                                'way_id': wid,
                                'distance_m': round(min_dist, 1),
                                'highway': tags.get('highway'),
                                'name': tags.get('name'),
                                'access': tags.get('access'),
                                'foot': tags.get('foot'),
                                'service': tags.get('service'),
                                'barrier': tags.get('barrier'),
                                'landuse': tags.get('landuse'),
                                'amenity': tags.get('amenity'),
                                'industrial': tags.get('industrial'),
                                'man_made': tags.get('man_made'),
                                'tags': tags
                            })

            elem.clear()
            while elem.getprevious() is not None:
                del elem.getparent()[0]

    print(f"[{time.strftime('%X')}] Pass 2 complete. Analyzing each of the 25 points...")

    # 3. Analyze each point
    audit_results = []
    for i, p in enumerate(pts):
        nearby_ways = sorted(pt_ways[i], key=lambda x: x['distance_m'])

        # Check walkable ways vs non-walkable or private
        walkable_50m = [w for w in nearby_ways if w['distance_m'] <= 50.0 and w['highway'] in {
            'footway', 'path', 'pedestrian', 'steps', 'living_street', 'residential', 'service', 'unclassified', 'tertiary', 'secondary', 'primary'
        } and w['access'] not in ('no', 'private') and w['foot'] not in ('no', 'private')]

        walkable_100m = [w for w in nearby_ways if w['distance_m'] <= 100.0 and w['highway'] in {
            'footway', 'path', 'pedestrian', 'steps', 'living_street', 'residential', 'service', 'unclassified', 'tertiary', 'secondary', 'primary'
        } and w['access'] not in ('no', 'private') and w['foot'] not in ('no', 'private')]

        private_or_restricted_nearby = [w for w in nearby_ways if w['distance_m'] <= 100.0 and (
            w['access'] in ('private', 'no') or w['foot'] in ('private', 'no') or w['service'] in ('driveway', 'internal')
        )]

        facility_clues = [w for w in nearby_ways if w['distance_m'] <= 150.0 and (
            w['landuse'] in ('industrial', 'plant', 'commercial', 'construction') or
            w['man_made'] in ('water_works', 'reservoir', 'storage_tank', 'wastewater_plant') or
            w['amenity'] in ('water_point', 'drinking_water') or
            w['barrier'] in ('wall', 'fence') or
            'sedapal' in str(w['tags']).lower() or 'atarjea' in str(w['tags']).lower()
        )]

        # Classification
        nearest_d = p['nearest_walkable_edge_distance_m']
        classification = []
        notes = []

        if 50.0 < nearest_d <= 100.0:
            classification.append("NEAREST_EDGE_50_TO_100M")
            notes.append(f"Vía caminable más cercana a {nearest_d:.1f} m (conecta si umbral se eleva a 100 m).")
        elif nearest_d > 100.0:
            classification.append("NO_WALKABLE_EDGE_WITHIN_50M")
            notes.append(f"Vía caminable más cercana a {nearest_d:.1f} m (excede 100 m).")

        if private_or_restricted_nearby:
            classification.append("MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY")
            w = private_or_restricted_nearby[0]
            notes.append(f"Existe vía con acceso restringido en OSM a {w['distance_m']} m (Way #{w['way_id']}, access={w['access']}, foot={w['foot']}).")

        if facility_clues:
            classification.append("INSIDE_MAPPED_FACILITY_SUSPECTED")
            fc = facility_clues[0]
            notes.append(f"Infraestructura o polígono de instalación identificado en OSM ({fc.get('name') or fc.get('man_made') or fc.get('landuse')}).")

        if 'cerro' in p['location_description'].lower() or 'laderas' in p['location_description'].lower() or 'lomas' in str(p['official_code']).lower():
            classification.append("TERRAIN_OR_ELEVATION_REVIEW_REQUIRED")
            notes.append("Topografía de ladera o cerro observada en la descripción.")

        # Check if it looks like infrastructure vs access location
        if p['component_type_raw'] in ('Pozo', 'Reservorio', 'Cámara de rebombeo') or 'RP' in str(p['official_code']) or 'RAP' in str(p['official_code']):
            classification.append("POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION")
            notes.append("Componente de infraestructura física donde la coordenada puede representar el activo y no el portón de despacho.")

        if not classification:
            classification.append("UNKNOWN_NEEDS_FIELD_VALIDATION")
            notes.append("Requiere inspección de campo para determinar el acceso peatonal real.")

        # Find nearest OSM way overall
        nearest_osm_way = nearby_ways[0] if nearby_ways else {}

        result_item = {
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
            'latitude': p['latitude'],
            'longitude': p['longitude'],
            'nearest_walkable_edge_distance_m': nearest_d,
            'snap_30m': p['snap_30m'],
            'snap_50m': p['snap_50m'],
            'snap_100m': p['snap_100m'],
            'nearest_osm_way_id': nearest_osm_way.get('way_id'),
            'nearest_osm_way_distance_m': nearest_osm_way.get('distance_m'),
            'nearest_osm_highway_type': nearest_osm_way.get('highway'),
            'nearest_osm_name': nearest_osm_way.get('name'),
            'nearest_osm_access': nearest_osm_way.get('access'),
            'nearest_osm_foot': nearest_osm_way.get('foot'),
            'nearest_osm_service': nearest_osm_way.get('service'),
            'technical_access_classification': " | ".join(classification),
            'requires_institutional_validation': "YES",
            'notes': " ".join(notes)
        }
        audit_results.append(result_item)
        print(f"Point FID {p['source_fid']} ({p['official_code']}): nearest_edge={nearest_d}m, nearest_osm_way={nearest_osm_way.get('distance_m')}m ({nearest_osm_way.get('highway')}), class={' | '.join(classification[:2])}")

    # Write JSON results
    out_audit_json = 'tools/offline_routing_spike/water_point_access_audit_full.json'
    with open(out_audit_json, 'w') as f:
        json.dump(audit_results, f, indent=2)
    print(f"Wrote {out_audit_json}")

if __name__ == '__main__':
    main()
