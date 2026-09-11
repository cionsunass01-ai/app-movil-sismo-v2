# Especificación del Formato Binario del Grafo Peatonal (CSR Layout)

## 1. Motivación y Principios de Diseño

El procesamiento y routing de grafos de gran escala en dispositivos móviles con recursos limitados impone restricciones severas:
1. **Evitar la presión de Garbage Collection (GC)**: Parsear formatos como JSON o instanciar 855,857 objetos `Node` y 1,990,320 objetos `Edge` en Dart generaría más de 3 millones de objetos en heap, provocando pausas de GC de varios segundos y picos de memoria > 200 MB.
2. **Estructuras de Memoria Contigua (CSR - Compressed Sparse Row)**: En lugar de punteros o listas anidadas, el grafo se almacena como una secuencia de arreglos tipados continuos (`TypedData`), permitiendo indexación directa $O(1)$ en memoria nativa sin overhead de objetos.
3. **Representación de Coordenadas en Microgrados (Int32)**: Se analizó el error de representación espacial en las coordenadas de Lima (`Lat ~ -12.0°, Lon ~ -77.0°`):
   * `Float32`: Error espacial máximo de **41.4 cm** (media 20.9 cm).
   * `Int32 Microgrados (1e-6°)`: Error espacial máximo de **7.5 cm** (media 4.2 cm).
   * `Float64`: Precisión sub-milimétrica pero requiere el doble de memoria (16 bytes vs 8 bytes por nodo).
   * **Decisión**: Se adopta **Int32 Microgrados** ($10^{-6}$ grados), logrando una precisión de 7.5 cm (óptima para navegación peatonal) consumiendo exactamente los mismos 4 bytes por coordenada que Float32 y garantizando determinismo entero libre de redondeos de coma flotante.

---

## 2. Layout Binario Detallado (Especificación AGUACSR1)

El archivo binario `pedestrian_graph_lima_csr.bin` consta de una cabecera fija de 64 bytes seguida de 7 secciones contiguas de datos empaquetados en orden *Little-Endian*.

```
+-----------------------------------------------------------------------+
|  HEADER (64 Bytes)                                                    |
|  Magic(8B) | Version(4B) | Pad(4B) | Hash(8B) | Counts(12B) | Bbox(16B)|
+-----------------------------------------------------------------------+
|  SECCIÓN 1: node_lats [node_count * 4 Bytes] (Int32 Microgrados)       |
+-----------------------------------------------------------------------+
|  SECCIÓN 2: node_lons [node_count * 4 Bytes] (Int32 Microgrados)       |
+-----------------------------------------------------------------------+
|  SECCIÓN 3: node_offsets [(node_count + 1) * 4 Bytes] (Uint32)        |
+-----------------------------------------------------------------------+
|  SECCIÓN 4: edge_targets [directed_edges * 4 Bytes] (Uint32)          |
+-----------------------------------------------------------------------+
|  SECCIÓN 5: edge_weights [directed_edges * 2 Bytes] (Uint16 Decímetro) |
+-----------------------------------------------------------------------+
|  SECCIÓN 6: edge_ids [directed_edges * 4 Bytes] (Uint32)               |
+-----------------------------------------------------------------------+
|  SECCIÓN 7: edge_flags [directed_edges * 1 Byte] (Uint8 Bitmask)      |
+-----------------------------------------------------------------------+
```

### 2.1. Estructura de la Cabecera (64 Bytes)

| Offset | Campo | Tipo | Tamaño | Descripción / Valor |
| :---: | :--- | :---: | :---: | :--- |
| `0x00` | `magic` | `char[8]` | 8 Bytes | Cadena mágica identificadora: `b"AGUACSR1"` |
| `0x08` | `format_version` | `uint32` | 4 Bytes | Versión del formato (actual: `1`) |
| `0x0C` | `reserved0` | `uint32` | 4 Bytes | Relleno de alineación (`0x00000000`) |
| `0x10` | `dataset_hash` | `uint8[8]`| 8 Bytes | Primeros 8 bytes del SHA-256 del extracto fuente |
| `0x18` | `node_count` | `uint32` | 4 Bytes | Total de nodos en el grafo (`855,857`) |
| `0x1C` | `edge_count_undir`| `uint32` | 4 Bytes | Total de aristas no dirigidas (`995,160`) |
| `0x20` | `edge_count_dir` | `uint32` | 4 Bytes | Total de aristas dirigidas CSR (`1,990,320`) |
| `0x24` | `min_lat_e6` | `int32` | 4 Bytes | Latitud mínima en microgrados (`-12,495,797`) |
| `0x28` | `max_lat_e6` | `int32` | 4 Bytes | Latitud máxima en microgrados (`-11,603,535`) |
| `0x2C` | `min_lon_e6` | `int32` | 4 Bytes | Longitud mínima en microgrados (`-77,264,394`) |
| `0x30` | `max_lon_e6` | `int32` | 4 Bytes | Longitud máxima en microgrados (`-76,484,093`) |
| `0x34` | `reserved_pad` | `uint8[12]`| 12 Bytes | Relleno para completar 64 bytes (`b"\x00"*12`) |

---

### 2.2. Secciones de Datos Contiguos

1. **`node_lats` (`node_count * 4` bytes)**:
   Arreglo de enteros con signo de 32 bits (`Int32List`).
   Fórmula de conversión a grados: `lat = lat_e6 / 1,000,000.0`.
2. **`node_lons` (`node_count * 4` bytes)**:
   Arreglo de enteros con signo de 32 bits (`Int32List`).
   Fórmula de conversión a grados: `lon = lon_e6 / 1,000,000.0`.
3. **`node_offsets` (`(node_count + 1) * 4` bytes)**:
   Arreglo de enteros sin signo de 32 bits (`Uint32List`).
   Para el nodo $u$, sus aristas salientes están comprendidas en el rango:
   $$\text{aristas}(u) = [\text{node\_offsets}[u], \, \text{node\_offsets}[u+1])$$
   El grado del nodo es $\text{node\_offsets}[u+1] - \text{node\_offsets}[u]$. El último elemento siempre equivale a `edge_count_dir`.
4. **`edge_targets` (`edge_count_dir * 4` bytes)**:
   Arreglo de enteros sin signo de 32 bits (`Uint32List`).
   Identificador del nodo vecino destino $v \in [0, \text{node\_count}-1]$.
5. **`edge_weights` (`edge_count_dir * 2` bytes)**:
   Arreglo de enteros sin signo de 16 bits (`Uint16List`).
   Longitud física de la arista medida en **decímetros** ($0.1$ m).
   * Rango representable: $0.1$ m a $6,553.5$ m (ningún segmento peatonal en Lima excede los 6.5 km sin intersecciones).
   * Conversión: `distancia_metros = weight_dm / 10.0`.
6. **`edge_ids` (`edge_count_dir * 4` bytes)**:
   Arreglo de enteros sin signo de 32 bits (`Uint32List`).
   Identificador unívoco de la arista no dirigida original ($[0, \text{edge\_count\_undir}-1]$). Permite que el bloqueo de una calle o puente se registre con una sola inserción en el conjunto de exclusión `blocked_edge_ids.contains(id)`.
7. **`edge_flags` (`edge_count_dir * 1` byte)**:
   Arreglo de bytes sin signo (`Uint8List`). Máscara de bits:
   * `Bit 0 (0x01)`: `IS_BRIDGE` (Estructura de puente urbano).
   * `Bit 1 (0x02)`: `IS_PEDESTRIAN_EXCLUSIVE` (Vía peatonal, footway o path).
   * `Bit 2 (0x04)`: `IS_STEPS` (Escalera / gradas en laderas).

---

## 3. Métricas de Dimensionamiento Físico

| Componente | Elementos | Bytes por Elemento | Total Bytes | Tamaño (MB) |
| :--- | :---: | :---: | :---: | :---: |
| **Cabecera** | 1 | 64 B | 64 B | 0.00 MB |
| **node_lats** | 855,857 | 4 B | 3,423,428 B | 3.26 MB |
| **node_lons** | 855,857 | 4 B | 3,423,428 B | 3.26 MB |
| **node_offsets**| 855,858 | 4 B | 3,423,432 B | 3.26 MB |
| **edge_targets**| 1,990,320 | 4 B | 7,961,280 B | 7.59 MB |
| **edge_weights**| 1,990,320 | 2 B | 3,980,640 B | 3.80 MB |
| **edge_ids** | 1,990,320 | 4 B | 7,961,280 B | 7.59 MB |
| **edge_flags** | 1,990,320 | 1 B | 1,990,320 B | 1.90 MB |
| **TOTAL BINARIO EN DISCO** | — | — | **32,163,872 B** | **30.67 MB** |
| **TOTAL COMPRIMIDO GZIP** | — | — | **16,053,743 B** | **15.31 MB** |

---

## 4. Patrón de Consumo en Dart (Zero GC)

Al cargarse en Dart desde los assets o el almacenamiento interno:

```dart
final bytes = await file.readAsBytes();
final byteData = ByteData.sublistView(bytes);

// 1. Validar Magic y Versión
final magic = ascii.decode(bytes.sublist(0, 8));
assert(magic == 'AGUACSR1');

// 2. Mapear vistas directas sin clonar memoria
final nodeLats = Int32List.view(bytes.buffer, 64, nodeCount);
final nodeLons = Int32List.view(bytes.buffer, 64 + nodeCount * 4, nodeCount);
final nodeOffsets = Uint32List.view(bytes.buffer, 64 + nodeCount * 8, nodeCount + 1);
// ...
```

* **Tiempo de Carga**: **< 150 milisegundos** en dispositivo móvil.
* **Consumo de Memoria**: Exactamente **30.67 MB** de memoria contigua; cero objetos Dart creados en heap para nodos o aristas.
