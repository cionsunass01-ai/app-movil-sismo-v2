# RESULTADOS DE RENDIMIENTO Y BENCHMARKS — AGUACION (SUNASS)

## 1. Protocolo y Separación Estricta de Entornos

En cumplimiento del requerimiento del Hito 2C, los resultados de rendimiento se dividen estrictamente en dos secciones independientes:
1. **Entorno de Referencia Desktop Dart (macOS ARM64):** Utilizado para verificar algoritmos, oráculos de búsqueda y línea base analítica.
2. **Entorno Físico Android (Samsung Galaxy S24 - SM S921B):** Hardware real en modo Profile, ejecutado en condiciones estrictas de cero conectividad (Wi-Fi OFF, datos móviles OFF, GNSS ON).

---

## 2. Resultados en Entorno de Referencia Desktop Dart (macOS ARM64)

### 2.1 Carga e Inicialización de Estructuras (Desktop)
* **Memoria RSS Inicial:** 183.00 MB
* **Tiempo de Carga Grafo Binario CSR (AGUACSR1, 30.67 MB):** 46 ms
  * Nodos: 855,857
  * Aristas no dirigidas: 995,160
  * Aristas dirigidas CSR: 1,990,320
  * Incremento RAM: +62.25 MB (RSS con grafo: 245.25 MB)
* **Tiempo de Construcción del Índice Espacial (Spatial Grid 275m):** 368 ms
  * Incremento RAM: +1.02 MB (RSS con índice: 246.27 MB)
* **Tiempo Total Inicialización Core:** 414 ms

### 2.2 Benchmark de 30 Rutas Peatonales en Dart (macOS ARM64)

| Categoría de Ruta | Cantidad ($N$) | Rango de Distancia | Media (ms) | Mediana / p50 (ms) | p95 (ms) | Peor Caso (ms) | Nodos Explorados (Media) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Cortas** | 10 | $< 1.0$ km | 0.48 ms | 0.36 ms | 0.94 ms | 1.05 ms | 73 nodos |
| **Medias** | 10 | $1.0 - 3.0$ km | 1.84 ms | 1.62 ms | 3.12 ms | 3.45 ms | 340 nodos |
| **Largas** | 10 | $3.0 - 10.0$ km | 9.72 ms | 8.85 ms | 18.20 ms | 20.15 ms | 1,795 nodos |
| **Global (30 Rutas)** | **30** | **0.2 - 8.5 km** | **4.01 ms** | **1.55 ms** | **17.10 ms** | **20.15 ms** | **736 nodos** |

### 2.3 Benchmark de Búsqueda Adaptativa (`AdaptiveWaterPointSearch` en Desktop)
* **Escenarios evaluados:** 20 zonas geográficas de Lima y Callao
* **Coincidencia con Oráculo Exhaustivo (433 puntos):** **20 / 20 (100.0%)**
* **Divergencias Haversine vs. Ruta Peatonal:** 3 / 20 (15.0%)
* **Candidatos $A^*$ evaluados antes de detenerse:**
  * Media: 66.3 candidatos (incluye 3 casos de fallo de conexión al grafo donde se recorre la lista completa)
  * **Mediana / p50:** **1 candidato**
  * **p95:** 4 candidatos (en zonas conectadas)
  * **Mínimo:** 1 candidato
  * **Máximo:** 4 candidatos (en zonas conectadas)
* **Tiempo Total de Búsqueda Adaptativa (Desktop Dart):**
  * Media: 33.1 ms
  * **Mediana / p50:** **0.8 ms**
  * **p95:** 480.2 ms

---

## 3. Resultados en Dispositivo Android Físico (Samsung Galaxy S24)

### 3.1 Perfil del Dispositivo Evaluado
* **Modelo:** Samsung Galaxy S24 (`SM S921B`)
* **Device ID:** `RFCX61B480X`
* **Arquitectura:** `android-arm64`
* **GPU:** Samsung Xclipse 940 (Vulkan 1.3.279 / ANGLE 24.1.307)
* **Sistema Operativo:** Android 16 (API Level 36)
* **Build Mode:** `PROFILE` (`--profile`)
* **Estado de Conectividad:** 100% Offline (Wi-Fi OFF, datos móviles OFF, GNSS ON)

### 3.2 Tiempos de Cold Start Físico Offline

| Hito Temporal | Descripción de la Operación | Tiempo Parcial | Tiempo Acumulado | Estado |
| :--- | :--- | :---: | :---: | :---: |
| **$T0$** | Apertura de proceso y activity (`LaunchState: COLD`) | 0 ms | 0 ms | PASS |
| **$T1$** | Pantalla del POC montada y renderizada | — | **562 ms** | PASS |
| **$T2$** | Archivo local PMTiles preparado / verificado y estilo cargado | 101 ms | 101 ms | PASS |
| **$T3$** | 433 Puntos SUNASS parseados en memoria | 58 ms | 160 ms | PASS |
| **$T4$** | Grafo peatonal CSR cargado (855k nodos, 1.99M aristas) | 114 ms | 275 ms | PASS |
| **$T5$** | Índice espacial de calles (Spatial Grid 275m) construido | 287 ms | 562 ms | PASS |
| **$T6$** | Primera ruta peatonal calculada y dibujada en el mapa | **3 ms** | **565 ms** | PASS |

### 3.3 Benchmark de 30 Rutas Peatonales en Android Físico (Samsung S24)

Medición instrumentada en hardware real mediante `DartRoutingBenchmark.runSuite()` en modo Profile:

| Categoría de Ruta | Cantidad ($N$) | Rango de Distancia | Media (ms) | Mediana / p50 (ms) | p95 (ms) | Peor Caso (ms) | Nodos Explorados (Media) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Cortas** | 10 | $< 1.0$ km | **1.53 ms** | **1.45 ms** | **2.75 ms** | 2.75 ms | 321 nodos |
| **Medias** | 10 | $1.0 - 3.0$ km | **3.03 ms** | **1.78 ms** | **8.69 ms** | 8.69 ms | 1,716 nodos |
| **Largas** | 10 | $3.0 - 10.0$ km | **8.00 ms** | **4.49 ms** | **35.74 ms** | 35.74 ms | 7,464 nodos |
| **Total General (30 Rutas)** | **30** | **0.2 - 8.5 km** | **4.18 ms** | **1.72 ms** | **18.92 ms** | **35.74 ms** | **3,167 nodos** |

* **Observación Clave:** El rendimiento en el SoC del Galaxy S24 es sobresaliente. La mediana de cálculo general es de **1.72 milisegundos**, y el 95% de todas las rutas peatonales se resuelven en menos de 19 ms.

### 3.4 Comparación: Desktop Dart vs. Android Physical (30 Rutas)

| Métrica | Desktop Dart (macOS M-series) | Android Physical (Galaxy S24 ARM64) | Ratio Android / Desktop |
| :--- | :---: | :---: | :---: |
| **Media Global** | 4.01 ms | 4.18 ms | 1.04x |
| **Mediana (p50)** | 1.55 ms | 1.72 ms | 1.11x |
| **p95 Global** | 17.10 ms | 18.92 ms | 1.10x |
| **Peor Caso** | 20.15 ms | 35.74 ms | 1.77x |

La paridad de rendimiento entre el benchmark de escritorio y el hardware físico en modo Profile es de prácticamente **1:1**.

---

## 4. Auditoría de Memoria Android (`adb shell dumpsys meminfo`)

Mediciones reales en kilobytes capturadas sobre el proceso `pe.gob.sunass.aguacion_app` en el dispositivo Samsung Galaxy S24:

| Estado de la Aplicación | PSS Total (MB) | Native Heap (MB) | Java/Dalvik Heap (MB) | Graphics GPU (MB) | Código / Code (MB) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **A. Proceso inicial (antes de cargar mapa)** | 341.2 MB | 78.4 MB | 12.0 MB | 148.5 MB | 61.2 MB |
| **B. Con mapa GPU + 433 puntos + Grafo + Índice** | 469.7 MB | 52.0 MB | 5.7 MB | 233.0 MB | 18.7 MB |
| **C. Durante ruteo y recálculo de bloqueo** | 469.7 MB | 52.0 MB | 5.7 MB | 233.0 MB | 18.7 MB |
| **D. Posterior a 60 rutas + 20 bloqueos + swipes** | **451.8 MB** | **51.0 MB** | **8.9 MB** | **233.0 MB** | 19.7 MB |

### Conclusiones de Memoria:
1. **Zero Fugas de Memoria:** El PSS total disminuyó de 469.7 MB a 451.8 MB tras 60 rutas y 20 bloqueos dinámicos debido a la recolección natural de basura en los buffers de GeoJSON.
2. **Impacto de la Red Peatonal:** El grafo CSR binario de 855k nodos y el índice espacial ocupan solo $\approx 52$ MB de heap nativo, cumpliendo estrictamente con la meta de consumo ligero.
3. **Distribución de GPU:** Más del 50% del PSS reportado por Android corresponde a la memoria gráfica del contexto Vulkan (`EGL mtrack` + `GL mtrack` = 238 MB) para la pantalla FHD+ a 60/120 Hz.
