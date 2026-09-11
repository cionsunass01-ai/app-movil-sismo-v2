# Investigación Técnica: Motor de Routing Peatonal Offline

## 1. Resumen y Objetivos

El cálculo de rutas peatonales offline es el componente funcional más crítico de **AguaCION**. En un escenario de desastre mayor:
* El ciudadano no dispone de servidores en la nube ni de APIs de Google Maps u OSRM.
* Las distancias deben medirse **a pie (peatonales)** y no en vehículo.
* No se puede asumir que el punto más cercano en línea recta (fórmula de Haversine) sea el más rápido o seguro, debido a accidentes geográficos (ríos, barrancos, cerros) y barreras antrópicas (vías expresas, muros, autopistas).
* El motor debe permitir **penalizar o bloquear aristas en caliente** (puentes colapsados, vías anegadas, zonas de derrumbe).

---

## 2. Comparación Exhaustiva de Motores de Routing

Se investigaron y contrastaron cinco enfoques técnicos para la ejecución offline en dispositivos móviles:

### Opción A — Grafo Peatonal Propio + A* (Recomendado)
* **Arquitectura**: Grafo de adyacencia optimizado, compilado previamente a partir de OSM, empaquetado en formato binario plano o SQLite, y ejecutado mediante un algoritmo A* bidireccional / heurístico en Dart puro o micro-biblioteca C embebida.
* **100% Offline**: Sí, totalmente autocontenido.
* **Soporte Android e iOS**: 100% nativo y multiplataforma sin depender de bindings externos complejos ni herramientas NDK.
* **Integración con Flutter**: Nativa en Dart. No requiere puentes de plataforma (`MethodChannel`) ni serialización costosa por cada ruta.
* **Routing Peatonal**: Totalmente adaptado a las reglas peatonales peruanas (gradas, pasajes peatonales, bermas de puentes, exclusión de autopistas).
* **Bloqueo Dinámico de Aristas**: Trivial. Basta con mantener un conjunto en memoria de identificadores de aristas bloqueadas `Set<EdgeId>`.
* **Modificación de Pesos en Caliente**: Inmediata (multiplicadores por pendiente, reporte de congestión, zonas oscuras).
* **Consumo de Memoria**: ~15 a 25 MB de RAM.
* **Tiempo de Cálculo**: **0.8 ms** para distancias cortas (<1.5 km), **3.8 ms** para distancias medias (<5 km), **27 ms** para cruces distritales largos (>7 km).

### Opción B — GraphHopper Embebido
* **Estado Actual**: GraphHopper fue concebido en Java. El soporte para Android móvil está en desuso y desactualizado en las ramas modernas (8.x / 9.x).
* **Limitación iOS**: No es ejecutable en iOS sin emuladores de bytecode Java (RoboVM / Gluon), lo cual es inaceptable para una app de producción en Flutter.
* **Consumo de Recursos**: Requiere máquina virtual Java con un heap de memoria > 150 MB.
* **Veredicto**: **Descartado**.

### Opción C — Valhalla / valhalla-mobile
* **Estado Actual**: Motor C++ de alto desempeño desarrollado por Mapzen/Mapbox. `valhalla-mobile` cuenta con repositorios desactualizados y dependencias pesadas (GEOS, Boost, SQLite, Protobuf).
* **Compilación Móvil**: Generar binarios NDK para Android (arm64, armeabi-v7a) y frameworks Xcode para iOS mediante Dart FFI es altamente frágil y susceptible a roturas por actualizaciones de toolchain.
* **Generación de Tiles**: Requiere un pipeline complejo de compilación de teselas Valhalla en servidores Linux.
* **Veredicto**: **Descartado por excesiva complejidad operativa y riesgo de mantenimiento**.

### Opción D — Organic Maps (Motor omim)
* **Estado Actual**: Proyecto open-source sobresaliente en C++ (fork de Maps.me).
* **Integración**: La lógica de routing está fuertemente acoplada al sistema de archivos `.mwm` y a su propio renderizador OpenGL/Metal (más de 500,000 líneas de C++). Extraer únicamente el motor de routing para consumirlo desde Flutter es un esfuerzo de ingeniería desproporcionado y difícil de mantener.
* **Veredicto**: **Excelente referencia conceptual, pero inviable como componente modular en Flutter**.

### Opción E — BRouter
* **Estado Actual**: Motor de routing en Java muy eficiente en OsmAnd.
* **Limitación iOS**: Solo funciona en Android (como servicio Android o librería Java). No tiene soporte para iOS.
* **Veredicto**: **Descartado por falta de soporte en iOS**.

---

## 3. Especificación del Grafo Peatonal Propio de Lima y Callao

### 3.1. Reglas de Filtrado de Vías (OSM Tags)
Para garantizar una red estrictamente transitable a pie en la realidad urbana de Lima y Callao:
* **Vías de tránsito peatonal exclusivo o prioritario (Incluidas)**:
  * `highway=footway`, `highway=path`, `highway=pedestrian`, `highway=steps` (escaleras esenciales en asentamientos humanos y cerros de Comas, Rímac, SJL), `highway=living_street`, `highway=corridor`.
* **Vías urbanas mixtas con vereda/acera (Incluidas)**:
  * `highway=residential`, `highway=service`, `highway=unclassified`.
  * `highway=tertiary`, `highway=tertiary_link`, `highway=secondary`, `highway=secondary_link`, `highway=primary`, `highway=primary_link` (arterias y avenidas que poseen veredas y puentes peatonales de cruce distrital).
* **Vías de Tránsito Rápido (Excluidas estrictamente)**:
  * `highway=motorway`, `highway=motorway_link` (Vía de Evitamiento, tramos expresos de Panamericana Norte/Sur, trinchera abierta de la Vía Expresa Paseo de la República sin puente peatonal).
  * `highway=trunk`, `highway=trunk_link` (salvo que contengan explícitamente `sidewalk=yes/both` o `foot=yes`).
  * `access=no`, `access=private`, `foot=no`.
  * `highway=construction`, `highway=proposed`.

### 3.2. Métricas y Dimensionamiento del Grafo
A partir de `Lima.osm.gz` (471,866 vías inspeccionadas en 8.4 s):
* **Vías caminables retenidas**: 200,472 vías.
* **Nodos activos del grafo**: **855,857 nodos**.
* **Aristas no dirigidas**: **995,160 aristas** (1,991,534 dirigidas).
* **Aristas en puentes catalogados**: 1,604 puentes.
* **Componente conexo principal**: 772,114 nodos (90.2% de la red metropolitana unificada).

### 3.3. Comparativa de Formatos y Pesos de Persistencia

| Formato | Descripción | Tamaño en Disco | Tiempo de Carga / Conversión |
| :--- | :--- | :---: | :---: |
| **JSON Crudo** | Estructura legible de nodos y aristas | 89.04 MB | 0.78 s |
| **JSON Comprimido (`.json.gz`)** | JSON empaquetado con Gzip | 19.25 MB | 0.84 s |
| **Base de Datos SQLite (`.db`)** | Tablas indexadas `nodes` y `edges` | 92.51 MB | 1.07 s |
| **Binario Plano (`.bin`)** | Structs empaquetados C/Dart (4B ID + 4B Lat + 4B Lon) | 23.50 MB | 0.12 s |
| **Binario Plano Comprimido (`.bin.gz`)** | Binario optimizado para transporte/asset | **11.44 MB** | 0.25 s |

---

## 4. Benchmarks Experimentales: A* vs Dijkstra

Se ejecutó una batería de 15 rutas de prueba representativas de viajes cortos, medios y largos en Lima Metropolitana y Callao sobre el grafo de 855,857 nodos:

| Categoría | Distancia Media | Tiempo A* (ms) [Media / p50 / p95] | Tiempo Dijkstra (ms) [Media / p50 / p95] | Nodos A* | Nodos Dijkstra | Aceleración A* |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Cortas (<1.5 km)** | 1.06 km | **0.83 ms** / 0.84 ms / 1.69 ms | 2.48 ms / 2.60 ms / 3.55 ms | 457 | 2,165 | **4.0x** |
| **Medias (2.5–5 km)** | 3.05 km | **3.82 ms** / 5.15 ms / 5.58 ms | 20.32 ms / 18.98 ms / 32.37 ms | 2,001 | 17,157 | **6.8x** |
| **Largas (5–9 km)** | 6.88 km | **27.46 ms** / 21.35 ms / 47.33 ms | 120.52 ms / 73.90 ms / 219.66 ms | 13,327 | 91,956 | **4.6x** |
| **Total General** | 3.66 km | **10.70 ms** / 5.15 ms / 45.04 ms | 47.77 ms / 18.98 ms / 209.77 ms | 5,262 | 37,092 | **5.1x** |

### Conclusiones del Benchmark:
1. **A* con heurística de Haversine** reduce en más de un **85% el espacio de búsqueda**, reduciendo la exploración de decenas de miles de nodos a un cono dirigido hacia el objetivo.
2. El tiempo de cálculo de A* en una CPU estándar es de **menos de 5 milisegundos para distancias típicas de abastecimiento de emergencia** (1 a 3 km).
3. Este rendimiento garantiza que en un dispositivo móvil gama media-baja el cálculo tarde menos de 25 ms, permitiendo una experiencia completamente fluida sin congelar la UI.

---

## 5. Evidencia Experimental con los 433 Puntos SUNASS: Haversine vs Ruta Peatonal Real

Uno de los postulados teóricos del proyecto era verificar si la distancia en línea recta (Haversine) induce a errores de selección al ciudadano. En el laboratorio se demostró empíricamente que **sí existen divergencias críticas causadas por barreras urbanas y topográficas**:

### Caso 1: Los Olivos frente a la Panamericana Norte
* **Ubicación del Ciudadano**: Av. Las Palmeras / Los Olivos (`Lat -11.9750, Lon -77.0650`).
* **Punto más cercano por Haversine (Línea Recta)**:
  `WP-SED-COM-25F4024735` (Ubicado en Independencia). Distancia en línea recta: **1,064 metros**.
  * **Distancia peatonal real**: **1,722 metros** (el ciudadano debe desviarse para encontrar un puente peatonal que cruce la autopista Panamericana Norte).
* **Punto más cercano por Ruta Peatonal Real**:
  `WP-SED-COM-F13489AE32` (Ubicado en Los Olivos, en el mismo margen urbano). Distancia en línea recta: **1,158 metros** (aparentemente más lejano en línea recta).
  * **Distancia peatonal real**: **1,633 metros**.
* **Impacto**: La fórmula Haversine hace que el ciudadano camine **90 metros adicionales** y cruce innecesariamente una autopista de alto riesgo.

### Caso 2: Comas La Balanza (Topografía Accidentada / Cerros)
* **Ubicación del Ciudadano**: Zona alta de La Balanza / Collique (`Lat -11.9250, Lon -77.0350`).
* **Punto más cercano por Haversine**: `WP-SED-COM-86E2EDE493`.
  * Distancia en línea recta: **645 metros**.
  * Distancia peatonal real por trama urbana: **1,024 metros**.
* **Punto más cercano por Ruta Peatonal**: `WP-SED-COM-CD653EF862`.
  * Distancia en línea recta: **661 metros**.
  * Distancia peatonal real: **906 metros**.
* **Impacto**: El algoritmo de ruta real ahorra **118 metros de caminata en pendiente (1.8 minutos a paso de emergencia)**.

---

## 6. Simulación de Bloqueo de Aristas en Caliente

Se simuló la inhabilitación del cruce del Río Rímac entre el Cercado de Lima y el Rímac (e.g. colapso estructural del puente principal):
* **Ruta Base (Condición Normal)**:
  Distancia: **1,420.27 m** | Nodos explorados: 931 | Tiempo de cálculo: 1.62 ms.
* **Incidente de Emergencia**: Se ingresó el borde `(10001015677, 10001015678)` en el conjunto `blocked_edges`.
* **Recálculo de Ruta**:
  Nueva distancia: **1,497.53 m** (+77.3 m de desvío por cruce alterno seguro) | Tiempo de recálculo: **1.30 ms**.
* **Resultado**: El motor recalculó la ruta instantáneamente identificando el puente adyacente transitable sin requerir reconstruir el grafo ni reindexar la base de datos.
