# Informe de Validación y Endurecimiento del POC Offline en Flutter (Hito 2C)

## 1. Alcance y Objetivos Cumplidos

Se ha completado el endurecimiento y la validación física en hardware real Android del **Proof of Concept (POC) Funcional** de navegación offline para **AguaCION / Agua Segura Perú (SUNASS)**. El flujo implementado demuestra en Flutter:

$$\mathbf{GNSS/GPS} \longrightarrow \mathbf{Ubicación} \longrightarrow \mathbf{433\ Puntos\ SUNASS} \longrightarrow \mathbf{PMTiles\ Local} \longrightarrow \mathbf{Grafo\ CSR} \longrightarrow \mathbf{Snap\ a\ Segmento} \longrightarrow \mathbf{A^*\ Peatonal} \longrightarrow \mathbf{Polyline\ en\ Mapa}$$

Todo el pipeline se ejecuta **100% desconectado de Internet** sobre un dispositivo físico **Samsung Galaxy S24 (`SM S921B`, Android 16 / API 36)** y se encuentra aislado dentro del directorio `lib/poc/offline_navigation/`.

---

## 2. Decisiones de Arquitectura y Correcciones de Endurecimiento

### 2.1. Visualización Cartográfica: MapLibre + PMTiles Directo
* **Motor Gráfico:** MapLibre Native Flutter (`maplibre_gl` 0.27.1) renderizando sobre la GPU Samsung Xclipse 940 mediante Vulkan 1.3.279.
* **Acceso a PMTiles:** Protocolo nativo directo `pmtiles://file://...` abriendo el archivo local mediante `mmap` sin sockets HTTP:
  $$\mathbf{LOCAL\_LOOPBACK\_SERVER\_USED = NO}$$
* **Estilo Vectorial Local:** `emergency_geometric_style.json` autocontenido, con 0 dependencias remotas (`http://` o `https://`).
* **Estado de Etiquetas:**
  $$\mathbf{OFFLINE\_LABELS\_WORKING = NO \quad (Diseño\ Geométrico\ Consciente)}$$
  $$\mathbf{BLOCKER\_FOR\_CITIZEN\_PILOT = YES \quad \mid \quad BLOCKER\_FOR\_ARCHITECTURAL\_POC = NO}$$

### 2.2. Sustitución de la Regla $N=5$ por Búsqueda Adaptativa
* Se descartó definitivamente la regla fija arbitraria $N = 5$.
* Se implementó **`AdaptiveWaterPointSearch`** basado en la cota geodésica inferior (desigualdad triangular):
  $$\text{Si } h(O, P_k) \ge D_{\text{best}} \implies \text{Detener Búsqueda}$$
* Verificado contra el **Oráculo Exhaustivo de 433 puntos**: 100.0% de coincidencia exacta en los 20 escenarios evaluados.

### 2.3. Snapping Endurecido con Costes Parciales de Segmento
* Proyección tangencial continua $X = A + t(B - A)$ con parámetro $t \in [0, 1]$.
* Inyección exacta de costes de entrada y salida:
  * $X \to A = t \cdot L$
  * $X \to B = (1 - t) \cdot L$
  * $C \to Y = t_{\text{dest}} \cdot L_{\text{dest}}$
  * $D \to Y = (1 - t_{\text{dest}}) \cdot L_{\text{dest}}$
* Si origen y destino coinciden en la misma arista: travesía directa $|t_{\text{orig}} - t_{\text{dest}}| \cdot L$.
* Cero redondeo ciego al nodo más próximo.

### 2.4. Purga de Terminología de Seguridad
* Eliminadas expresiones que sugieran seguridad no garantizada ("ruta segura", "desvío seguro").
* Terminología canónica adoptada:
  * *“Ruta peatonal calculada según la información cartográfica disponible”*
  * *“Ruta alternativa según el grafo disponible”*

---

## 3. Resultados Clave de la Validación Física en Samsung Galaxy S24

* **Dispositivo:** Samsung Galaxy S24 (`SM S921B`), Device ID: `RFCX61B480X`, `android-arm64`, Android 16 (API 36).
* **Modo:** `PROFILE` (`flutter build apk --profile`).
* **Conectividad:** Wi-Fi OFF, datos móviles OFF, GPS ON (cero Internet verificado).
* **Cold Start Total ($T0 \dots T6$):**
  * $T0$: Proceso COLD (750 ms)
  * $T1$: Pantalla POC montada: **562 ms**
  * $T2$: PMTiles listo: **101 ms**
  * $T3$: 433 Puntos parseados: **58 ms**
  * $T4$: Grafo CSR (855k nodos, 1.99M aristas) cargado: **114 ms**
  * $T5$: Spatial Grid 275m construido: **287 ms**
  * $T6$: Primera ruta calculada y visible: **3 ms**
* **Benchmark 30 Rutas Peatonales en Android:**
  * Rutas Cortas ($<1$ km): Media = **1.53 ms** | p50 = **1.45 ms**
  * Rutas Medias ($1-3$ km): Media = **3.03 ms** | p50 = **1.78 ms**
  * Rutas Largas ($3-10$ km): Media = **8.00 ms** | p50 = **4.49 ms**
  * Total 30 Rutas: Media = **4.18 ms** | **Mediana (p50) = 1.72 ms** | Peor caso = **35.74 ms**
* **Memoria Android:**
  * Baseline inicial: 341.2 MB PSS
  * Con mapa GPU + 433 puntos + Grafo + Índice: 469.7 MB PSS (Graphics GPU: 233.0 MB, Native Heap: 52.0 MB, Java Heap: 5.7 MB)
  * Posterior a 60 rutas y 20 bloqueos: **451.8 MB PSS** (cero fugas de memoria).
* **Estabilidad y Resistencia:** $>60$ rutas y 20 bloqueos dinámicos en caliente sin jank, sin ANRs y con 0 crashes.

---

## 4. Estructura de Archivos del POC Endurecido

```
lib/poc/offline_navigation/
├── benchmarks/
│   └── dart_routing_benchmark.dart
├── graph/
│   └── csr_graph.dart
├── models/
│   ├── gnss_state.dart
│   ├── route_result.dart
│   └── snap_result.dart
├── presentation/
│   └── offline_navigation_poc_page.dart
├── routing/
│   ├── adaptive_water_point_search.dart
│   └── astar_router.dart
├── services/
│   ├── offline_location_service.dart
│   └── pmtiles_manager.dart
└── spatial/
    └── edge_spatial_grid.dart
```

---

## 5. Veredictos del Hito 2C

* `ANDROID_OFFLINE_MAP = PASS`
* `ANDROID_OFFLINE_GNSS = PASS`
* `ANDROID_COLD_START_OFFLINE = PASS`
* `ANDROID_STABILITY = PASS`
* `LOCAL_LOOPBACK_SERVER_USED = NO`
* `OFFLINE_LABELS_WORKING = NO` (Bloqueante piloto ciudadano: SÍ | Bloqueante POC técnico: NO)
* **`POC OFFLINE FLUTTER VALIDADO = YES`**
