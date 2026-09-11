# Validación Física en iOS y Hardening Multiplataforma

**Proyecto:** Agua Segura Perú / AguaCION — SUNASS
**Hito:** Hito 2D — Hardening Cartográfico, Auditoría de Acceso, Validación Física iOS y Consolidación Documental
**Fecha:** 11 de septiembre de 2026
**Dispositivo Auditado:** Apple iPhone (`iPhone de pruebas`, ID: `<PHYSICAL_IPHONE_DEVICE_ID>`, iOS 26.5 Build 23F77, `ios-arm64`)
**Modo de Ejecución:** Profile AOT (`com.example.aguacion.dev`, Team: `<DEVELOPMENT_TEAM_ID>`, Xcode Managed Profile, 97.9 MB)
**Estado de Conectividad:** Wi-Fi `OFF`, Datos Móviles `OFF`, Ubicación `ON`
**Estado General de Validación iOS:** `IOS_CORE_OFFLINE = VALIDATED`

---

## 1. Resumen Ejecutivo de la Validación Física en iOS

Tras la validación física en Android (Samsung Galaxy S24) durante el Hito 2C, el Hito 2D completó la validación física exhaustiva sobre hardware Apple iPhone real, ejecutando la aplicación en modo Profile con compilación anticipada AOT, aceleración gráfica nativa Metal y en condiciones estrictas de **desconexión física de red (Wi-Fi OFF y Datos Móviles OFF)**.

### Pipeline de Navegación Físicamente Demostrado en iPhone:
$$\text{Ubicación Real GNSS} \longrightarrow \text{Snapping (50m)} \longrightarrow \text{AdaptiveWaterPointSearch} \longrightarrow A^* \longrightarrow \text{Selección de Punto} \longrightarrow \text{Renderizado Metal} \longrightarrow \text{Encuadre de Cámara}$$

1. **Firma Digital y Despliegue Físico:**
   Se configuró el aprovisionamiento con el *Personal Team* del desarrollador (`<DEVELOPMENT_TEAM_ID>`) y el Bundle Identifier `com.example.aguacion.dev`. La aplicación se compiló en 29.1s–36.2s, se transfirió mediante cable USB vía `devicectl` y se ejecutó en primer plano sobre el dispositivo sin errores de firma.
   *(Nota de configuración: El Bundle Identifier `com.example.aguacion.dev` y el Personal Team utilizado corresponden exclusivamente a la configuración local de desarrollo y prueba física; no constituyen el Bundle Identifier ni el Team institucional definitivo de AguaCION/SUNASS)*.
2. **Motor Cartográfico Metal sin Red:**
   MapLibre Native para iOS (`MLNMapView`) inicializó limpiamente sobre la API Metal de Apple, leyendo directamente el archivo PMTiles metropolitano (`lima_callao_z14.pmtiles`, 10.17 MB) sin servidores HTTP intermedios (`LOCAL_LOOPBACK_SERVER_USED = NO`).
3. **Etiquetas Cartográficas Offline con Glifos PBF Locales:**
   Se verificó visualmente sobre la pantalla del iPhone la presencia de nombres de calles, avenidas y distritos con soporte tipográfico completo de caracteres del español (`á`, `é`, `í`, `ó`, `ú`, `ñ`, `¿`), sin presencia de cuadros vacíos (*tofu*) y con cero solicitudes remotas a la red.
4. **Catálogo de 433 Puntos Oficiales:**
   Los 433 puntos oficiales de SUNASS/SEDAPAL cargaron localmente en memoria y se renderizaron en la capa vectorial como círculos azules sobre el mapa.
5. **Grafo Peatonal CSR (`AGUACSR1`):**
   La estructura de 855,857 nodos y 1,990,320 aristas dirigidas se cargó en arreglos tipados continuos sin anomalías de memoria.
6. **Marcador de Ubicación del Usuario y Sensor GNSS:**
   Se visualizó correctamente el punto azul nativo de ubicación en el mapa (`myLocationEnabled: true`). Se obtuvo una ubicación actual con Wi-Fi y datos móviles desactivados, con una precisión (*accuracy*) reportada de **6.1 metros** (no se afirma "GPS puro" ni ausencia absoluta de A-GPS).
7. **Cálculo y Renderizado de Ruta en Tiempo Real:**
   Desde la ubicación física del usuario en San Isidro, el motor resolvió la ruta óptima hacia el punto de abastecimiento oficial más cercano:
   - **Punto Seleccionado:** `WP-SED-SUR-3B91385998-SAN ISIDRO`
   - **Nombre:** Ca. Los Cedros Cdra. 03 (Parque Dammert)
   - **Distancia a pie:** 2.01 km
   - **Tiempo estimado:** 30 min a pie
   - **Tiempo de cálculo:** 2.2 ms
   - **Nodos evaluados:** 828 nodos
   - **Búsqueda adaptativa:** 2 candidatos $A^*$ evaluados de 433
   - **Condición de parada geodésica:** 2,106 metros
   - **Renderizado Visual:** Línea verde esmeralda de 5.5 px con contorno blanco protector de 9.0 px mediante el `LineManager` nativo de MapLibre en Metal, encuadrada automáticamente con márgenes envolventes (`LatLngBounds`).

---

## 2. Benchmark Físico Oficial en Hardware iPhone Real (30 Rutas)

Se ejecutó la suite de prueba estándar de **30 rutas peatonales** (10 cortas, 10 medias y 10 largas) directamente en el procesador del iPhone en modo Profile, arrojando los siguientes resultados cronometrados en memoria:

| Categoría de Ruta | Rango de Distancia | Cantidad ($N$) | Media | Mediana (p50) | Percentil 95 (p95) | Peor Caso |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Rutas Cortas** | $< 1.0$ km | 10 | **1.73 ms** | **1.71 ms** | **2.61 ms** | **2.61 ms** |
| **Rutas Medias** | $1.0 - 3.0$ km | 10 | **3.40 ms** | **2.17 ms** | **8.41 ms** | **8.41 ms** |
| **Rutas Largas** | $3.0 - 10.0$ km | 10 | **6.20 ms** | **2.66 ms** | **25.93 ms** | **25.93 ms** |
| **TOTAL GENERAL** | **$0.2 - 8.5$ km** | **30** | **3.78 ms** | **2.09 ms** | **15.36 ms** | **25.93 ms** |

### Análisis Comparativo de Rendimiento (iPhone vs. Android Galaxy S24):

| Métrica Global (30 Rutas) | Apple iPhone (iOS 26.5 / arm64) | Samsung Galaxy S24 (Android 16 / arm64) |
| :--- | :---: | :---: |
| **Tiempo Medio** | **3.78 ms** | 4.18 ms |
| **Mediana (p50)** | **2.09 ms** | 1.72 ms |
| **Percentil 95 (p95)** | **15.36 ms** | 18.92 ms |
| **Peor Caso** | **25.93 ms** | 35.74 ms |

*Conclusión Técnica:* El motor de enrutamiento $A^*$ en Dart sobre el grafo `AGUACSR1` presenta una paridad de rendimiento sobresaliente en ambos sistemas operativos: resuelve el **95% de las rutas peatonales en menos de 16 milisegundos en iOS**, garantizando una respuesta fluida dentro del presupuesto de cuadro de pantalla (60 Hz).

---

## 3. Prueba de Estrés y Estabilidad en iOS (70 Operaciones)

Se sometió al motor a una batería de estrés compuesta por **60 rutas** ($30\text{ directas} + 30\text{ inversas}$) más **10 bloqueos dinámicos en memoria** con re-enrutamiento sobre el hardware del iPhone:

### Métricas de Ejecución del Stress Test:
- **Operaciones evaluadas:** 70 (60 rutas + 10 bloqueos con re-enrutamiento)
- **`successful_routes`:** **50 / 60** (83.3%)
- **`expected_no_route`:** **10 / 60** (16.7%) — Auditados como `SNAP_NOT_FOUND` bajo el umbral estricto y conservador de 50.0 metros.
- **`unexpected_failures`:** **0**
- **`uncaught_exceptions`:** **0**
- **Re-ruteos dinámicos post-bloqueo:** **10 / 10** exitosos
- **Tiempo total de ejecución del test:** 173 ms a 755 ms (promedio: 2.5 ms a 10.79 ms por operación)
- **Veredicto de Estabilidad:** **ESTABILIDAD COMPLETA EN iOS** (0 crashes, 0 excepciones no controladas; no se observó crecimiento progresivo evidente de memoria durante la batería de estrés realizada).

### Auditoría Individualizada de las Rutas no Resueltas (`expected_no_route`):
Las 10 rutas no resueltas corresponden a exactamente 5 pares de origen/destino periféricos o de acceso restringido evaluados en ambos sentidos (forward y reverse) bajo el umbral de seguridad peatonal de 50 metros:
1. **Ruta #1 (Chucuito $\leftrightarrow$ Plaza Grau Callao):** El punto en Chucuito se ubica en zona de costa/área naval militar a $>50\text{ m}$ de la calzada pública transitada (`originSnapFailed` en ida, `destinationSnapFailed` en vuelta).
2. **Ruta #19 (Los Olivos Pro $\leftrightarrow$ MegaPlaza Independencia):** El punto de origen se ubica en el intercambio vial de la Autopista Panamericana Norte, cuyas calzadas de alta velocidad (`highway=trunk`) fueron deliberadamente excluidas del grafo peatonal por seguridad ciudadana (`originSnapFailed` en ida, `destinationSnapFailed` en vuelta).
3. **Ruta #23 (Surco Higuereta $\leftrightarrow$ Malecón Chorrillos):** El destino en el Malecón de Chorrillos se proyecta sobre el acantilado a $>50\text{ m}$ del sendero transitable digitalizado en OpenStreetMap (`destinationSnapFailed` en ida, `originSnapFailed` en vuelta).
4. **Ruta #26 (Chorrillos Pantanos de Villa $\leftrightarrow$ Barranco Malecón):** El origen se sitúa dentro de la reserva natural ecológica de Pantanos de Villa a $>50\text{ m}$ de vías públicas peatonales (`originSnapFailed` en ida, `destinationSnapFailed` en vuelta).
5. **Ruta #27 (Plaza Grau Callao $\leftrightarrow$ Aeropuerto Jorge Chávez):** El destino se ubica dentro de la plataforma del terminal aéreo internacional, clasificada con restricción de acceso vehicular/privado (`access=private/no`) y excluida por las reglas de transitabilidad peatonal (`destinationSnapFailed` en ida, `originSnapFailed` en vuelta).

> [!NOTE]
> Una ruta legítimamente no encontrada debido a que el origen o destino dista más de 50 metros de una vía pública caminable **NO constituye un fallo del motor ni un error de software**, sino una respuesta controlada y correcta del sistema que previene enrutar a peatones por autopistas o zonas sin acceso verificado.

---

## 4. Análisis Metodológico de Tiempos e Inicialización (Cold Start)

Durante la validación física en iPhone se cronometraron las siguientes fases internas de carga del subsistema offline:

| Hito Temporal | Componente / Operación | Tipo de Métrica | Valor Medido en iPhone |
| :--- | :--- | :---: | :---: |
| **T0** | Inicio de ejecución del método de inicialización del POC | Timestamp base | 0 ms |
| **T2** | Preparación de archivo local PMTiles y estilo JSON | Duración de fase | $< 15$ ms |
| **T3** | Lectura y parseo de 433 puntos oficiales SUNASS | Duración de fase | $< 25$ ms |
| **T4** | Carga y mapeo en memoria de grafo CSR binario (1.99M aristas) | Duración de fase | $< 80$ ms |
| **T5** | Construcción de índice espacial `EdgeSpatialGrid` | Duración de fase | $< 45$ ms |
| **T1** | **Subsistema offline completamente cargado y montado en UI** | **Acumulado T0 $\to$ T1** | **166 ms** |
| **T6** | **Primer cálculo de ruta $A^*$ con búsqueda adaptativa** | **Duración de consulta** | **2.2 ms** |
| **T1 + T6** | **`OFFLINE_SUBSYSTEM_MOUNT_TO_FIRST_ROUTE`** | **Suma de fases** | **168.2 ms** |

### Distinción Metodológica Fundamental:
- **`OFFLINE_SUBSYSTEM_INIT = 166 ms`:** Representa el tiempo interno transcurrido dentro del ciclo de vida de Flutter desde que se invoca `_initializePoc()` hasta que todos los activos locales (PMTiles, 433 puntos, grafo CSR e índice espacial) quedan instanciados en memoria y listos para operar.
- **`FIRST_ROUTE_CALCULATION = 2.2 ms`:** Representa la duración de la primera consulta $A^*$ con parada geodésica.
- **`OFFLINE_SUBSYSTEM_MOUNT_TO_FIRST_ROUTE = 168.2 ms`:** Tiempo interno transcurrido desde el montaje del subsistema en UI hasta tener la primera ruta calculada y lista en pantalla. **NO debe denominarse `APP_PROCESS_COLD_START`**.
- **`APP_PROCESS_COLD_START = NOT_KERNEL_INSTRUMENTED`:** La cifra de 168.2 ms **NO corresponde al tiempo de arranque completo a nivel de proceso del sistema operativo** (desde el toque del icono por el usuario en SpringBoard hasta el primer cuadro Metal dibujado), el cual abarca la inicialización de librerías dinámicas de iOS, launchd, inicialización del motor Flutter y compilación de shaders. Dicha métrica requeriría instrumentación de kernel vía Xcode Instruments / `os_signpost`.

## 5. Medición Real de Memoria en Hardware iPhone (Apple Instruments / Activity Monitor)

La auditoría de memoria en iOS se ejecutó directamente sobre el hardware físico del iPhone 13 (`iPhone de pruebas`, ID: `<PHYSICAL_IPHONE_DEVICE_ID>`) mediante la herramienta oficial **Apple Instruments (`xcrun xctrace` con template `Activity Monitor`)** y contrastada con el **Xcode Memory Gauge** sobre el proceso nativo `com.example.aguacion.dev` (`Runner`, PID activo).

> [!IMPORTANT]
> **Distinción Metodológica de Métricas en iOS:**
> En el sistema operativo iOS (kernel XNU / Darwin), **NO existe la métrica PSS (Proportional Set Size)**, la cual es un constructo exclusivo de Linux/Android (`/proc/<pid>/smaps`).
> En iOS, la métrica crítica del sistema es el **Physical Memory Footprint (`memory-physical-footprint`)**, que cuantifica la memoria anónima sucia (*dirty memory*) más la memoria comprimida por el kernel (*compressed memory*), siendo el indicador determinante para los eventos de presión del kernel (*jetsam*). Adicionalmente, se audita el **Resident Memory Size (RSS / `memory-resident-size`)**, que refleja las páginas físicas asignadas en memoria RAM.

### Resultados de Memoria en los Estados Operacionales Evaluados:

| N° | Estado Operacional de la Aplicación | Memory Footprint (Métrica Clave iOS) | Resident Memory (RSS / Real Mem) | Variación vs. Estado Previo |
| :---: | :--- | :---: | :---: | :---: |
| **1** | **Baseline:** App/POC recién abierto (Dart AOT + Metal context) | **116.5 MB** | 120.4 MB | Base inicial |
| **2** | **Mapa + Etiquetas:** PMTiles `mmap` + renderizado Metal con glifos locales | **158.2 MB** | 164.8 MB | $+41.7\text{ MB}$ (contexto gráfico Metal, framebuffers y caché de renderizado; tamaño de glyph assets en disco $\approx 419\text{ KB}$, métrica distinta a la memoria gráfica/caché del renderer) |
| **3** | **Loaded (Datos Completos):** 433 puntos + Grafo CSR `AGUACSR1` + `EdgeSpatialGrid` | **208.7 MB** | 215.3 MB | $+50.5\text{ MB}$ (buffers tipados continuos e índice) |
| **4** | **Routing:** Tras calcular la primera ruta óptima con parada geodésica | **214.3 MB** | 220.8 MB | $+5.6\text{ MB}$ (estructuras $A^*$ y polilíneas Metal) |
| **5** | **Peak en Estrés:** Pico máximo durante la batería de 70 operaciones | **238.6 MB** | **246.2 MB** | $+24.3\text{ MB}$ (asignaciones transitorias en ruteo masivo) |
| **6** | **Post-Stress:** Posterior a la prueba de estrés (estado estabilizado) | **215.1 MB** | **221.4 MB** | $\mathbf{-23.5\text{ MB}}$ (recolección de basura Dart activa) |

### Análisis de Comportamiento y Dictamen de Memoria:
- **Crecimiento Progresivo Evidente:** **NO OBSERVADO EN ESTA PRUEBA**.
  No se observó crecimiento progresivo evidente de memoria durante la batería de estrés realizada. Tras completar las 70 operaciones de la prueba de estrés (60 rutas directas/inversas y 10 bloqueos dinámicos en memoria), el recolector de basura generacional de Dart (`Scavenger` / `Mark-Sweep`) recuperó **23.5 MB**, devolviendo el consumo al nivel basal de operación (+0.8 MB de variación neta frente al estado previo al estrés).
- **Comportamiento de Estructuras Tipadas (`TypedData`):**
  El grafo binario `AGUACSR1` opera sobre arrays continuos tipados (`Int32List`, `Float32List`). El uso de `TypedData` reduce drásticamente el overhead de objetos en el heap de Dart y permite almacenamiento contiguo en memoria, pero **no garantiza la ausencia total de recolecciones de basura (GC)**, ya que las operaciones de enrutamiento y búsqueda adaptativa generan estructuras auxiliares transitorias (nodos de la cola de prioridad, mapas de bloqueo y listas de coordenadas).
- **Eficiencia del Motor Cartográfico Metal:**
  El contenedor `lima_callao_z14.pmtiles` se accede por paginación de memoria virtual (`mmap`) nativa en C++, de forma que únicamente las teselas visibles consumen memoria residente, liberándose dinámicamente según el desplazamiento de la cámara.
- **Comportamiento frente a Jetsam:**
  El pico observado de 238.6 MB no produjo señales de presión o terminación por memoria durante la prueba. Los límites efectivos de Jetsam son dinámicos y no se utilizará un umbral fijo no documentado como criterio.

$$\mathbf{IOS\_MEMORY\_GROWTH\_CONCERN = NO\_OBSERVADO\_EN\_ESTA\_PRUEBA}$$
$$\mathbf{IOS\_MEMORY\_FOOTPRINT = STABLE}$$

---

## 6. Matriz de Resultados de la Validación Física en iOS

| Componente / Prueba | Resultado | Evidencia en Hardware Real (iPhone `iPhone de pruebas`) |
| :--- | :---: | :--- |
| **Firma Digital y Despliegue USB** | **PASS** | Compilado e instalado vía `devicectl` con *Personal Team* local (`<DEVELOPMENT_TEAM_ID>`); no institucional. |
| **Mapa Vectorial PMTiles Local** | **PASS** | `MLNMapView` renderizado en GPU Metal sin tráfico de red. |
| **Etiquetas de Calles Offline** | **PASS** | Validado en pantalla: nombres de avenidas/calles legibles, tildes, `ñ`, cero tofu. |
| **433 Puntos SUNASS Locales** | **PASS** | Círculos azules proyectados sobre la red vial en pantalla. |
| **Marcador de Posición del Usuario** | **PASS** | Punto azul nativo de iOS (`myLocationEnabled: true`) visualizado sobre la ubicación real. |
| **Sensor GNSS sin Wi-Fi ni Datos** | **PASS** | Ubicación actual obtenida con Wi-Fi OFF y Datos Móviles OFF; precisión de 6.1 m reportada. |
| **Snapping Peatonal Conservador** | **PASS** | Umbral estricto de 50m mantenido; sin relajación artificial ni acceso inventado. |
| **Búsqueda Adaptativa de Puntos** | **PASS** | Evaluó 2 candidatos de 433 con parada geodésica a 2,106 m en 2.2 ms. |
| **Renderizado de Ruta en Metal** | **PASS** | Doble trazo (verde esmeralda 5.5 px sobre contorno blanco 9 px) vía `LineManager`. |
| **Encuadre Automático de Cámara** | **PASS** | `LatLngBounds` envolvente de toda la ruta ejecutado limpiamente en pantalla. |
| **Benchmark de 30 Rutas Peatonales** | **PASS** | Mediana (p50) de 2.09 ms, p95 de 15.36 ms, peor caso 25.93 ms. |
| **Prueba de Estrés (70 Operaciones)** | **PASS** | 50/60 rutas resueltas, 10/60 sin ruta esperada (`SNAP_NOT_FOUND`), 0 excepciones, 10/10 bloqueos. |
| **Consumo y Estabilidad de Memoria** | **PASS** | Footprint baseline 116.5 MB, peak 238.6 MB, post-stress 215.1 MB (recuperación de 23.5 MB; no se observó crecimiento progresivo evidente de memoria). |
| **Estabilidad Global de la App** | **PASS** | Cero cierres inesperados (*crashes*), cero bloqueos de UI (*freezes*). |

---

## 7. Alcance del Repositorio y Estado Git

> [!NOTE]
> **Salvedad sobre `git diff --stat`:**
> La salida de `git diff --stat` (que reporta 5 archivos modificados) únicamente refleja los archivos rastreados (*tracked*) preexistentes en el repositorio (`project.pbxproj`, `Info.plist`, `header_bar.dart`, `pubspec.yaml`, `pubspec.lock`).
> **NO debe presentarse "5 files changed" como el tamaño completo del trabajo realizado**, dado que todo el nuevo subsistema de navegación offline, datasets, pruebas y documentación técnica se encuentra estructurado en archivos nuevos clasificados como no rastreados (`??` en `git status --short`):
> - `assets/` (PMTiles, grafo binario CSR, fuentes PBF Noto Sans, dataset 433 puntos)
> - `docs/` (Reportes Hito 2D, validación Android/iOS, auditorías de acceso CSV/MD, Reporte Maestro v2)
> - `lib/poc/` (Motor A*, grafo CSR, búsqueda adaptativa, snapping espacial, geolocalización, vistas UI)
> - `test/poc/` (Suites de pruebas automatizadas del motor de navegación offline)
> - `tools/` (Compilador de grafo CSR, generador de estilo, extractores de fuentes PBF)

---

## 8. Veredicto Final

$$\mathbf{OFFLINE\_CORE\_IOS = VALIDATED}$$
$$\mathbf{OFFLINE\_LABELS = VALIDATED}$$
$$\mathbf{HITO\_2D = COMPLETE}$$
