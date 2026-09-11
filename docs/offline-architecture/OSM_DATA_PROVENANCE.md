# Proveniencia y Metadata de Datos Cartográficos (OSM Lima + Callao)

Este documento certifica y registra la procedencia, integridad criptográfica, cobertura geográfica y términos legales de los extractos cartográficos de OpenStreetMap utilizados en el Spike Técnico de AguaCION / Agua Segura Perú (SUNASS).

---

## 1. Identificación de la Fuente Primaria

* **Proyecto de Origen**: OpenStreetMap (OSM) — Base de datos cartográfica colaborativa mundial.
* **Proveedor de Extracto Certificado**: BBBike (Plataforma especializada en extractos urbanos de OpenStreetMap).
* **Licencia de los Datos**: Open Database License (ODbL) 1.0.
* **Requisitos de Atribución Obligatoria**:
  > "© OpenStreetMap contributors. Datos disponibles bajo la Licencia de Bases de Datos Abierta (ODbL)."
* **URL de Descarga Canónica PBF**:
  `https://download.bbbike.org/osm/bbbike/Lima/Lima.osm.pbf`
* **URL de Descarga Canónica GZ**:
  `https://download.bbbike.org/osm/bbbike/Lima/Lima.osm.gz`
* **URL del Polígono Límite**:
  `https://download.bbbike.org/osm/bbbike/Lima/Lima.poly`

---

## 2. Parámetros de Cobertura Geográfica (Bounding Box)

El polígono oficial de corte BBBike para Lima comprende las siguientes coordenadas en WGS84:

| Extremo Geográfico | Longitud (Lon) | Latitud (Lat) |
| :--- | :---: | :---: |
| **Sudoeste (SW)** | -77.260000 | -12.420000 |
| **Nordeste (NE)** | -76.560000 | -11.700000 |

### Verificación de Cobertura de los 433 Puntos de Agua SUNASS:
* **Extremos de los 433 puntos auditados**:
  * Latitud: `[-12.235877, -11.818060]` (100% contenido en `[-12.42, -11.70]`).
  * Longitud: `[-77.160908, -76.772472]` (100% contenido en `[-77.26, -76.56]`).
* **Conclusión**: El extracto cubre el 100% de los puntos de abastecimiento de Lima Metropolitana y la Provincia Constitucional del Callao, con un margen de resguardo perimetral de más de 10 km.

---

## 3. Integridad Criptográfica y Tamaños de Archivos Crudos

Los archivos fueron descargados e inspeccionados directamente en el laboratorio técnico:

| Archivo | Formato | Tamaño en Bytes | Tamaño (MB) | Hash SHA-256 |
| :--- | :---: | :---: | :---: | :--- |
| `Lima.osm.pbf` | Protocolbuffer Binario | 30,161,750 | 28.76 MB | `6bf7056dcf12d533832c25cd8a9d33cc1ae1b1d842c98daf08d6e00f8fcd4b49` |
| `Lima.osm.gz` | XML comprimido Gzip | 63,328,403 | 60.39 MB | `8056bc6fd5baa3178eddd328ce5624e85537815fd5ce920fc8801a7b4c7a245f` |
| `Lima.poly` | Polígono texto | 77 | 0.08 KB | `e971485ea4f8464654fe76db01b1a45a0dbd5870a4697669d675661448b1d9bf` |

---

## 4. Fuente de Construcción de Vector Tiles (PMTiles)

Para la evaluación del mapa visual vectorial, se utilizó el extracto espacial sobre el servicio global de compilación de Protomaps (basado en Planetiler y datos OSM):

* **Proveedor de Compilación**: Protomaps Global Builds (`build.protomaps.com`).
* **Build de Origen**: `20260908.pmtiles` (Compilación generada el 08 de septiembre de 2026).
* **Herramienta de Extracción Regional**: `pmtiles` v1.31.2 (Go binary oficial de Protomaps).
* **Comando de Reproducción**:
  ```bash
  # Variante A - Emergency Minimal (Zoom 0 a 12)
  pmtiles extract https://build.protomaps.com/20260908.pmtiles tools/offline_map_spike/lima_callao_z12.pmtiles \
    --bbox=-77.26,-12.42,-76.56,-11.70 --maxzoom=12

  # Variante B - Emergency Detailed (Zoom 0 a 14)
  pmtiles extract https://build.protomaps.com/20260908.pmtiles tools/offline_map_spike/lima_callao_z14.pmtiles \
    --bbox=-77.26,-12.42,-76.56,-11.70 --maxzoom=14
  ```

---

## 5. Política de Actualización y Regeneración

Los archivos `.pbf`, `.osm.gz` y `.pmtiles` no se versionan dentro de Git debido a su peso binario, cumpliendo con las buenas prácticas de ingeniería de software.
Cualquier desarrollador o entorno CI/CD puede regenerar exactamente los mismos artefactos ejecutando los scripts reproducibles:

```bash
# 1. Descarga de datos
curl -sSL -o tools/offline_routing_spike/raw/Lima.osm.gz https://download.bbbike.org/osm/bbbike/Lima/Lima.osm.gz

# 2. Compilación del grafo peatonal
python3 tools/offline_routing_spike/build_pedestrian_graph.py

# 3. Exportación de formatos optimizados
python3 tools/offline_routing_spike/export_graph_formats.py
```
