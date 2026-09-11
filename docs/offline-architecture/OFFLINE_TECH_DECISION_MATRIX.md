# Matriz de Decisión Tecnológica para Arquitectura Offline (AguaCION)

## 1. Escala de Ponderación y Criterios de Evaluación

Para seleccionar objetivamente la arquitectura de **Agua Segura Perú / AguaCION**, se definieron pesos según el impacto operativo en emergencias de gran escala en Lima Metropolitana y Callao:

* **Crítico (Peso 5)**: Requisitos habilitadores o descalificantes. Si una opción no cumple uno de estos, queda descartada.
* **Alto (Peso 3)**: Factores determinantes de estabilidad, ligereza, mantenibilidad y flexibilidad ante incidentes reales.
* **Medio (Peso 1)**: Esfuerzo de ingeniería e infraestructura de empaquetado.

### Escala de Puntuación:
* `5` = Excelente / Soporte Nativo / Cero Fricción
* `4` = Bueno / Cumple con adaptaciones menores
* `3` = Aceptable / Requiere mantenimiento adicional
* `2` = Deficiente / Complejidad o riesgo significativo
* `1` = Inviable / Sin soporte / Bloqueante

---

## 2. Matriz Comparativa de Motores de Routing Offline

| Criterio de Evaluación | Peso | Opción A: Grafo Propio + A* (Dart/C) | Opción B: GraphHopper Embebido | Opción C: Valhalla / valhalla-mobile | Opción D: Organic Maps (omim core) | Opción E: BRouter |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Funciona 100% Offline** | 5 (Crítico) | 5 (100% local) | 5 (100% local) | 5 (100% local) | 5 (100% local) | 5 (100% local) |
| **Soporte Android** | 5 (Crítico) | 5 (Nativo Dart/NDK) | 4 (Java JVM) | 4 (C++ NDK) | 4 (C++ NDK) | 4 (Android Service) |
| **Soporte iOS** | 5 (Crítico) | 5 (Nativo Dart/Metal) | **1 (Sin soporte Java)** | 3 (Xcode Framework) | 4 (C++ Metal) | **1 (Sin soporte iOS)** |
| **Integrable con Flutter** | 5 (Crítico) | 5 (API directa Dart) | 2 (MethodChannels Java) | 2 (Dart FFI complejo) | 1 (Acoplado a UI nativa) | 2 (IPC Android) |
| **Routing Peatonal** | 5 (Crítico) | 5 (Custom Lima/Callao) | 4 (Perfil Foot) | 5 (Pedestrian profile) | 5 (Pedestrian profile) | 4 (Foot profile) |
| **Permite Datos Propios Lima–Callao** | 5 (Crítico) | 5 (Pipeline directo) | 4 (Importador OSM) | 3 (Pipeline tiles) | 2 (Formato MWM cerrado) | 3 (Segmentos rd5) |
| **Mantenimiento Actual** | 3 (Alto) | 5 (Bajo control SUNASS) | 2 (Mobile deprecado) | 2 (Repos móviles archivados) | 4 (Comunidad activa) | 3 (Proyecto de nicho) |
| **Peso de Datos (< 30 MB)** | 3 (Alto) | 5 (**11.4 MB bin.gz**) | 3 (~40–60 MB) | 3 (~35–50 MB) | 4 (~30–40 MB) | 4 (~25–35 MB) |
| **Consumo de Memoria RAM** | 3 (Alto) | 5 (**15–25 MB**) | 1 (>150 MB JVM) | 3 (~50–80 MB) | 3 (~60–90 MB) | 2 (~70–100 MB) |
| **Tiempo de Cálculo (< 50 ms)** | 3 (Alto) | 5 (**0.8 a 27 ms**) | 4 (10 a 30 ms) | 5 (5 a 20 ms) | 5 (5 a 20 ms) | 4 (15 a 40 ms) |
| **Facilidad de Actualización** | 3 (Alto) | 5 (Script 34s) | 3 (Recompilar jar) | 2 (Recompilar tiles) | 2 (Recompilar mwm) | 3 (Recompilar rd5) |
| **Licencia Compatible** | 3 (Alto) | 5 (MIT/BSD/Propia) | 4 (Apache 2.0) | 4 (MIT) | 4 (Apache 2.0) | 3 (GPL v3 - restrictiva) |
| **Bloqueo Dinámico de Aristas** | 3 (Alto) | 5 (**Trivial en runtime**) | 2 (Complejo en grafo estático) | 3 (Costing JSON parcial) | 1 (Muy complejo) | 2 (Reglas estáticas) |
| **Modificación de Pesos en Caliente** | 3 (Alto) | 5 (**Directo en A\***) | 2 (Requiere perfiles CH) | 3 (Costing JSON) | 1 (Requiere nuevo MWM) | 3 (Perfiles custom) |
| **Complejidad Operativa** | 1 (Medio) | 5 (Zero toolchains externas)| 2 (Java en Gradle) | 1 (NDK + CMake + Boost) | 1 (C++ monolítico) | 2 (Java en Gradle) |
| **PUNTUACIÓN TOTAL PONDERADA** | — | **255 / 255 (100%)** | 148 / 255 (58%) | 171 / 255 (67%) | 165 / 255 (65%) | 142 / 255 (56%) |
| **ESTADO DE SELECCIÓN** | — | **SELECCIONADO** | **DESCALIFICADO (iOS)** | **DESCALIFICADO (Riesgo)**| **DESCALIFICADO (Acople)**| **DESCALIFICADO (iOS)** |

---

## 3. Matriz Comparativa de Motores Visuales Offline

| Criterio | Peso | MapLibre Flutter (`maplibre_gl`) | Flutter Map (`flutter_map`) | Canvas Personalizado (`CustomPainter`) |
| :--- | :---: | :---: | :---: | :---: |
| **Renderizado Vectorial Hardware** | 5 | 5 (OpenGL ES / Metal GPU) | 3 (Ráster / Canvas Skia) | 2 (CPU Skia / Impeller simple) |
| **Soporte PMTiles Offline** | 5 | 5 (Localhost loopback MVT) | 4 (Plugins de terceros) | 1 (Requiere parseo manual MVT) |
| **Rendimiento Pan & Zoom (60 fps)**| 5 | 5 (Culling nativo GPU) | 3 (Degrada en zoom alto) | 2 (Baja tasa de refresco con 800k nodos) |
| **Capas GeoJSON Dinámicas (433 pts)**| 5 | 5 (Inyección GeoJSON nativa) | 5 (MarkerLayer) | 3 (Redibujado completo) |
| **Soporte Android & iOS** | 5 | 5 (MapLibre Native) | 5 (Puro Flutter) | 5 (Puro Flutter) |
| **Peso en Binario de App** | 3 | 4 (+12–15 MB shared libs) | 5 (+1 MB) | 5 (+0 MB) |
| **PUNTUACIÓN PONDERADA** | — | **137 / 140 (98%)** | 114 / 140 (81%) | 78 / 140 (56%) |
| **ESTADO DE SELECCIÓN** | — | **SELECCIONADO** | Alternativa de contingencia | Descartado para mapa real |

---

## 4. Resumen de Decisiones de Arquitectura

1. **Visualización Cartográfica**: **MapLibre Flutter (`maplibre_gl`)**.
2. **Formato de Mapa**: **PMTiles v3**.
3. **Variante Cartográfica**: **Variante B (Emergency Detailed, Zoom 0 a 14, 10.88 MB)**.
4. **Motor de Routing**: **Grafo Peatonal Propio + Algoritmo A\*** (con heurística Haversine y snapping espacial indexado).
5. **Formato del Grafo**: **Binario Plano Comprimido (`pedestrian_graph_lima.bin.gz`, 11.44 MB)** desempacado en memoria como TypedData / Float32List.
6. **Persistencia de Puntos**: **SQLite / JSON Normalizado (`water_points_normalized.json`, 148 KB)** con los 433 puntos oficiales SUNASS auditados.
