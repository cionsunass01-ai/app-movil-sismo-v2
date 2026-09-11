# Reporte de Cierre: Hito 2D — Hardening Cartográfico, Auditoría de Acceso, Validación Física iOS y Consolidación Documental

**Proyecto:** Agua Segura Perú / AguaCION — SUNASS
**Hito:** Hito 2D
**Fecha:** 11 de septiembre de 2026
**Estado del Repositorio:** `flutter analyze 0 issues`, `15/15 tests pass`, cero dependencias remotas
**Dictamen Final del Hito:** `HITO_2D = COMPLETE`
**Documentos Técnicos Principales:**
- [`OFFLINE_LABELS_IMPLEMENTATION.md`](docs/offline-architecture/OFFLINE_LABELS_IMPLEMENTATION.md)
- [`WATER_POINT_ACCESS_AUDIT.md`](docs/offline-architecture/WATER_POINT_ACCESS_AUDIT.md)
- [`WATER_POINT_ACCESS_AUDIT.csv`](docs/offline-architecture/WATER_POINT_ACCESS_AUDIT.csv)
- [`IOS_PHYSICAL_VALIDATION.md`](docs/offline-architecture/IOS_PHYSICAL_VALIDATION.md)
- [`PROJECT_STATUS_AGUACION.md` (v2)](docs/PROJECT_STATUS_AGUACION.md)

---

## 1. Implementación de Etiquetas Cartográficas Offline (Labels & Glyphs)

### Auditoría del Contenedor PMTiles:
$$\mathbf{STREET\_NAME\_ATTRIBUTES\_PRESENT = YES}$$
Se auditó a bajo nivel el contenedor `lima_callao_z14.pmtiles` (10.17 MB) confirmando la presencia de cadenas de texto y atributos viales completos en las capas vectoriales:
- Capa `roads`: `name`, `name:es`, `ref`, `shield_text`, `kind`, `kind_detail` (más de 290 vías con nombre en una sola tesela z14 del Centro de Lima).
- Capa `places`: `name`, `name:es`, `kind` (`city`, `district`, `neighbourhood`, `suburb`).
- Capa `water`: `name`, `name:es`, `kind` (*Río Rímac*).
No se requirió regenerar el PMTiles.

### Tipografía y Glifos Locales:
- **Tipografía:** Noto Sans Regular y Noto Sans Bold.
- **Licencia:** SIL Open Font License (OFL) 1.1 (libre para distribución, embedding y uso gubernamental).
- **Formato:** Protocol Buffers comprimidos (`.pbf`), rangos `0-255.pbf` y `256-511.pbf` (419 KB en total).
- **Validación Visual en Pantalla Móvil:** Verificado físicamente en hardware iPhone real con Wi-Fi y datos móviles apagados:
  * Nombres de calles, avenidas y distritos visibles y legibles.
  * Tildes y acentos diacríticos del español operativos.
  * Carácter `ñ` operativo.
  * Cero presencia de caracteres rotos (*tofu*) o cuadrados vacíos.
  * Cero solicitudes remotas a la red (`0 / N`).

---

## 2. Auditoría Individualizada de los 25 Puntos sin Conexión (SNAP_NOT_FOUND)

Se analizó la totalidad de los 25 registros oficiales que con el umbral base experimental de 50 metros no encontraron segmento transitable en el grafo peatonal `AGUACSR1`:

### Hallazgos Principales:
1. **Comportamiento con Umbral de 100 Metros:**
   * **18 puntos (72.0%) se conectan limpiamente a la red peatonal urbana**, con una distancia media al segmento transitable de $69.8\text{ metros}$ (rango: 51.5 m a 97.8 m).
   * **7 puntos (28.0%) permanecen sin conexión (> 100 m):** FID 36 (136.7 m), FID 100 (228.5 m), FID 147 (102.0 m), FID 187 (109.1 m), FID 254 (142.4 m), FID 268 (108.6 m) y FID 296 (336.3 m).
2. **Evaluación de Reglas de Filtrado del Grafo:**
   * **Pozos de la Autopista Ramiro Prialé (SJL - FID 30, 31, 35, 36, 37):** La vía adyacente más próxima (entre 2.5 m y 29 m) es `highway=trunk`. El compilador del grafo excluyó correctamente estas calzadas de alta velocidad por seguridad vial del peatón.
   * **Vía con Restricción de Acceso (La Molina - FID 296):** El punto dista 26.1 m de una calle mapeada como `access=private`. El compilador excluyó adecuadamente esta arista privada, conectando a la red pública a 336.3 m.
   * **Laderas y Periferias (FID 100, 147, 187, 268):** Presentan sospecha técnica de vacíos de digitalización de pasajes o escaleras en OpenStreetMap (*OSM Path Gap*).
3. **Modelo Conceptual de Acceso:**
   * Se formalizó la entidad `WaterPointAccess` distinguiendo `infrastructureLocation` vs. `pedestrianAccessLocation`.
   * **Coordenadas de acceso ciudadano inventadas: EXACTAMENTE 0.**
   * Todas las discrepancias quedan tipificadas neutralmente como `PENDING_INSTITUTIONAL_VALIDATION`.
   * Se actualizaron las preguntas 8 y 9 en `docs/data-audit/INSTITUTIONAL_QUESTIONS_AGUACION.md`.

---

## 3. Estado de la Cartografía y Assets

| Recurso | Estado Anterior | Estado Post-Hito 2D | Motivo del Cambio |
| :--- | :---: | :---: | :--- |
| `lima_callao_z14.pmtiles` | 10.17 MB | 10.17 MB (Sin cambios) | Ya contenía los atributos textuales requeridos. |
| Fuentes PBF (`Noto Sans`) | 0 KB | 419 KB (4 archivos PBF) | Habilitación de renderizado tipográfico offline. |
| `emergency_geometric_style.json` | 2.3 KB | 4.8 KB | Incorporación de bloque `"glyphs"` y 4 capas de símbolos (`places_labels`, `water_labels`, `roads_major_labels`, `roads_minor_labels`). |
| Grafo CSR (`pedestrian_graph_lima_csr.bin.gz`)| 15.31 MB | 15.31 MB (Sin cambios) | Formato binario plenamente compatible. |
| Puntos Normalizados (`water_points_normalized.json`)| 0.82 MB | 0.82 MB (Sin cambios) | Integridad de datos oficiales preservada. |
| **Total Datos Distribuibles en Bundle** | **26.3 MB** | **26.7 MB** | Incremento marginal (+419 KB) por fuentes tipográficas. |

---

## 4. Validación Física en iOS (Apple iPhone Real)

### Dispositivo Auditado:
- **Modelo:** Apple iPhone (`iPhone de pruebas`)
- **Device ID:** `<PHYSICAL_IPHONE_DEVICE_ID>`
- **Versión del Sistema Operativo:** iOS 26.5 (Build 23F77, `ios-arm64`)
- **Modo:** Profile AOT (`com.example.aguacion.dev`, Team: `<DEVELOPMENT_TEAM_ID>`, 97.9 MB)
  *(Nota de configuración: El Bundle Identifier `com.example.aguacion.dev` y el Personal Team utilizado son configuración local de desarrollo y prueba física; no constituyen el Bundle ID ni el Team institucional definitivo de AguaCION/SUNASS)*.
- **Condición de Red:** Wi-Fi `OFF`, Datos Móviles `OFF`, Conexión USB física para captura de telemetría.

### Pipeline End-to-End Verificado Físicamente en iPhone:
El usuario ejecutó la aplicación sobre hardware real con desconexión física de red, verificando el flujo completo:
1. **Ubicación Ciudadana en Tiempo Real:** Visualización del punto azul nativo de ubicación (`myLocationEnabled: true`). Se obtuvo una ubicación actual con Wi-Fi y datos móviles desactivados, con una precisión (*accuracy*) reportada de **6.1 metros** (no se afirma "GPS puro" ni ausencia de A-GPS).
2. **Snapping Conservador a 50m:** Conexión estricta a la red peatonal urbana sin relajaciones artificiales ni suposiciones de acceso.
3. **Búsqueda Adaptativa y Parada Geodésica:** Evaluó 2 candidatos $A^*$ de 433, alcanzando la condición de parada geodésica a los 2,106 metros en **2.2 ms** con **828 nodos explorados**.
4. **Punto Seleccionado:** `WP-SED-SUR-3B91385998-SAN ISIDRO` — Ca. Los Cedros Cdra. 03 (Parque Dammert), a 2.01 km de caminata (30 min a pie).
5. **Renderizado de Ruta en Metal:** Visualización nítida de la línea verde esmeralda (5.5 px) con contorno blanco protector (9.0 px) mediante el `LineManager` nativo de MapLibre, encuadrada dinámicamente (`LatLngBounds`).
6. **Simulación de Bloqueo Dinámico:** Operativa en memoria permitiendo re-enrutar al instante.

### Resultados del Benchmark Físico de 30 Rutas Peatonales en iPhone:

| Categoría | Distancia | $N$ | Media | Mediana (p50) | Percentil 95 (p95) | Peor Caso |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Rutas Cortas** | $< 1.0$ km | 10 | **1.73 ms** | **1.71 ms** | **2.61 ms** | **2.61 ms** |
| **Rutas Medias** | $1.0 - 3.0$ km | 10 | **3.40 ms** | **2.17 ms** | **8.41 ms** | **8.41 ms** |
| **Rutas Largas** | $3.0 - 10.0$ km | 10 | **6.20 ms** | **2.66 ms** | **25.93 ms** | **25.93 ms** |
| **TOTAL GENERAL** | **$0.2 - 8.5$ km** | **30** | **3.78 ms** | **2.09 ms** | **15.36 ms** | **25.93 ms** |

### Paridad Multiplataforma (iPhone vs. Android Galaxy S24):
- **p50 Routing:** 2.09 ms en iPhone vs. 1.72 ms en Samsung Galaxy S24.
- **p95 Routing:** 15.36 ms en iPhone vs. 18.92 ms en Samsung Galaxy S24.
- **Peor Caso:** 25.93 ms en iPhone vs. 35.74 ms en Samsung Galaxy S24.
- **Estabilidad:** 0 crashes, 0 UI freezes en ambas plataformas; no se observó crecimiento progresivo evidente de memoria durante la batería de estrés realizada.

### Auditoría de la Prueba de Estrés (70 Operaciones a 50m Estricto):
- **`successful_routes`:** 50 / 60 (83.3%)
- **`expected_no_route`:** 10 / 60 (16.7%) — Auditados como `SNAP_NOT_FOUND` a 50m en 5 zonas no peatonales o periféricas (Chucuito base naval, Los Olivos Pro autopista, Malecón Chorrillos acantilado, Pantanos de Villa reserva, Aeropuerto plataforma restringida).
- **`unexpected_failures`:** 0
- **`uncaught_exceptions`:** 0
- **Re-ruteos dinámicos:** 10 / 10 exitosos.
- **Tiempo total del test:** 173 ms – 755 ms (promedio: 2.5 ms – 10.79 ms por operación).

### Análisis Metodológico de Inicialización (Cold Start):
- **`T1` (Subsistema offline listo y montado en UI):** 166 ms (tiempo acumulado de lectura de assets, parseo JSON, mapeo de grafo CSR e índice espacial en Flutter).
- **`T6` (Duración del primer cálculo de ruta $A^*$):** 2.2 ms.
- **`OFFLINE_SUBSYSTEM_MOUNT_TO_FIRST_ROUTE = 168.2 ms`:** Tiempo interno transcurrido desde el montaje del subsistema offline en UI hasta primera ruta calculada. **NO debe denominarse `APP_PROCESS_COLD_START`**.
- **Distinción de proceso SO (`APP_PROCESS_COLD_START = NOT_KERNEL_INSTRUMENTED`):** La cifra de 168.2 ms corresponde a la inicialización interna dentro de Flutter; **no incluye el cold start a nivel de proceso del sistema operativo**, el cual requiere instrumentación externa de bajo nivel vía Instruments.

### Medición Real de Memoria en Hardware iPhone (Apple Instruments):
- **Herramienta de Medición:** Apple Instruments (`xcrun xctrace` con template `Activity Monitor`) contrastada con Xcode Memory Gauge sobre el proceso nativo `com.example.aguacion.dev` (`Runner`) en el iPhone 13 físico (`iPhone de pruebas`).
- **Métrica Oficial Registrada:** **Physical Memory Footprint (`memory-physical-footprint`)** y **Resident Size (RSS)**. (No se reporta PSS al ser una métrica exclusiva del kernel Linux/Android).
- **Consumo por Estados Operacionales:**
  1. *Baseline (App recién abierta):* **116.5 MB Footprint** (120.4 MB Resident Size).
  2. *Mapa + Etiquetas:* **158.2 MB Footprint** (164.8 MB Resident Size) — Contexto gráfico Metal, framebuffers y caché de renderizado; tamaño de glyph assets en disco $\approx 419\text{ KB}$, métrica distinta a la memoria gráfica/caché del renderer.
  3. *Loaded (433 Puntos + Grafo CSR + Rejilla):* **208.7 MB Footprint** (215.3 MB Resident Size).
  4. *Tras calcular ruta (Routing):* **214.3 MB Footprint** (220.8 MB Resident Size).
  5. *Pico durante stress test (Peak):* **238.6 MB Footprint** (246.2 MB Resident Size).
  6. *Tras el stress test (Post-Stress):* **215.1 MB Footprint** (221.4 MB Resident Size).
- **Veredicto de Memoria:** **`IOS_MEMORY_GROWTH_CONCERN = NO_OBSERVADO_EN_ESTA_PRUEBA`**. No se observó crecimiento progresivo evidente de memoria durante la batería de estrés realizada. La memoria se estabilizó tras el pico de esfuerzo (-23.5 MB tras 70 operaciones). El uso de `TypedData` (`Int32List`, `Float32List`) reduce el overhead de objetos en el heap de Dart y permite buffers contiguos, pero no garantiza la ausencia total de recolecciones de basura (GC). Asimismo, el pico observado de 238.6 MB no produjo señales de presión o terminación por memoria durante la prueba; los límites efectivos de Jetsam son dinámicos y no se utilizará un umbral fijo no documentado como criterio.

---

## 5. Alcance del Repositorio y Estado Git

> [!NOTE]
> **Salvedad sobre `git diff --stat`:**
> La salida de `git diff --stat` (que muestra 5 archivos modificados) solo incluye los archivos versionados preexistentes en el repositorio. **NO debe presentarse "5 files changed" como el tamaño completo del trabajo realizado**, dado que la totalidad del motor de navegación offline, datasets normalizados, pruebas unitarias y documentación técnica se encuentra distribuida en archivos nuevos no rastreados (`??` en `git status --short`):
> - `assets/` (PMTiles 10.17 MB, Grafo CSR 15.31 MB, Glifos PBF 419 KB, 433 Puntos 0.82 MB)
> - `docs/` (Reportes de auditoría, validación física iOS/Android, reporte maestro v2)
> - `lib/poc/` (Código fuente completo del subsistema de navegación offline)
> - `test/poc/` (Batería automatizada de tests de routing, oráculo y glifos)
> - `tools/` (Scripts de geoprocesamiento, compresión y verificación)

---

## 6. Veredicto Final de Cierre del Hito 2D

| Componente Evaluado | Criterio de Aceptación | Dictamen |
| :--- | :--- | :---: |
| **Hardening de Etiquetas Cartográficas** | Tipografía local PBF, 0 HTTP, calles visibles sin tofu | **VALIDATED** |
| **Auditoría de Acceso (25 Puntos)** | Análisis individualizado, taxonomía neutral, 0 inventados | **COMPLETE** |
| **Núcleo Offline Android** | PMTiles directo, Grafo CSR, A*, GNSS sin red probado físicamente | **VALIDATED** |
| **Núcleo Offline iOS** | PMTiles Metal directo, 30 rutas en hardware físico, Wi-Fi/Datos OFF | **VALIDATED** |
| **Pipeline de Navegación iOS** | Ubicación real, snapping 50m, ruta renderizada en Metal, encuadre | **VALIDATED** |
| **Memoria y Estabilidad iOS** | Footprint: baseline 116.5 MB, peak 238.6 MB, post-stress 215.1 MB; no se observó crecimiento progresivo evidente | **VALIDATED** |
| **Consolidación Documental** | Reporte Maestro v2 con 18 correcciones y métricas físicas reales | **UPDATED** |
| **DICTAMEN GENERAL HITO 2D** | Cumplimiento integral del hito | **COMPLETE** |

$$\mathbf{HITO\_2D = COMPLETE}$$
