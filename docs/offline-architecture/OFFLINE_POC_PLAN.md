# Plan de Implementación para el POC de Mapas y Routing Offline (Hito 3)

## 1. Alcance y Objetivos del Hito 3

Tras cerrar exitosamente el **Hito 1 (Auditoría de Datos)** y el **Hito 2 (Spike Técnico Experimental)**, el Hito 3 tendrá como objetivo integrar de forma controlada la arquitectura validada en la aplicación móvil Flutter **AguaCION**:

$$\text{GNSS/GPS Offline} \longrightarrow \text{433 Puntos SUNASS} \longrightarrow \text{Snapping a Grafo} \longrightarrow \text{A* Peatonal} \longrightarrow \text{Visualización MapLibre}$$

Todo el flujo deberá funcionar de principio a fin **sin conexión a Internet**.

---

## 2. Fases de Ejecución del POC

### Fase 1: Preparación y Empaquetado de Activos Cartográficos
1. **Compilar Activos Finales de Lima + Callao**:
   * Mapa vectorial: `assets/maps/lima_callao_z14.pmtiles` (10.88 MB).
   * Grafo de routing: `assets/routing/pedestrian_graph_lima.bin.gz` (11.44 MB).
   * Puntos de agua normalizados: `assets/data/water_points_normalized.json` (148 KB con los 433 puntos oficiales).
   * Estilo vectorial MapLibre: `assets/styles/emergency_style.json`, glifos PBF locales y sprites de iconos de emergencia.
2. **Presupuesto Total de Activos Empaquetados**: **~22.5 MB**, cumpliendo estrictamente con el objetivo de paquete liviano (< 30–50 MB).

### Fase 2: Implementación de la Capa de Servicios Offline (Core)
1. **Servidor Local de Teselas (PMTiles Proxy)**:
   * Crear `lib/core/services/pmtiles_server_service.dart`.
   * Implementar servidor HTTP en bucle local (`127.0.0.1:port`) utilizando `dart:io` (`HttpServer`) o `shelf`.
   * Servir teselas MVT leyendo offsets de bytes directos del archivo PMTiles con `RandomAccessFile`.
2. **Motor de Routing Peatonal en Dart**:
   * Crear `lib/core/routing/pedestrian_router.dart`.
   * Desempaquetar el binario en estructuras tipadas (`Uint32List` para aristas y `Float32List` para coordenadas) para minimizar consumo de memoria en garbage collection.
   * Implementar algoritmo A* con heurística de Haversine y snapping espacial con celdas de rejilla.
   * Exponer API reactiva: `calculateRoute(UserLocation start, WaterPoint destination, {Set<EdgeId> blockedEdges})`.
3. **Optimización del Servicio GNSS/GPS (`LocationService`)**:
   * Corregir el timeout restrictivo de 5 segundos (ampliar a 30–45s para cold start en modo avión).
   * Incorporar lectura inmediata de `getLastKnownPosition()` como estimación inicial.
   * Retener `accuracy` (precisión en metros) y `timestamp` en el modelo `UserLocation`.
   * Implementar banner de estado de adquisición de satélites GNSS.

### Fase 3: Integración Visual en Flutter UI
1. **Actualizar `pubspec.yaml`**:
   * Incorporar la dependencia oficial de `maplibre_gl`.
   * Registrar las carpetas de activos offline (`assets/maps/`, `assets/routing/`, `assets/styles/`).
2. **Sustituir `vector_map_painter.dart`**:
   * Reemplazar el canvas simulado por el widget interactivo `MapLibreMap`.
   * Configurar estilo local (`http://127.0.0.1:port/style.json`).
   * Configurar límites de cámara (`cameraTargetBounds`) restringidos al Bounding Box de Lima y Callao `[-77.26, -12.42] - [-76.56, -11.70]`.
   * Inyectar los 433 puntos de agua como capa de símbolos/círculos en GPU.
   * Dibujar la ruta calculada como `LineLayer` (color verde de evacuación segura `#10B981` con contorno blanco).

### Fase 4: Funcionalidades Dinámicas y Experiencia de Usuario
1. **Selección Inteligente por Ruta Real (y no Haversine)**:
   * Al recibir la ubicación GPS, calcular los mejores candidatos según la red caminable, eliminando falsas recomendaciones separadas por autopistas o ríos.
2. **Gestión de Calles/Puentes Bloqueados**:
   * Permitir al usuario (o simulador de defensa civil) marcar un tramo como intransitable.
   * Recalcular la ruta en menos de 20 milisegundos y mostrar el desvío seguro en pantalla.

---

## 3. Protocolo de Pruebas en Dispositivos Físicos (Android & iOS)

Las pruebas definitivas de validación deben ejecutarse en teléfonos físicos según los 4 escenarios de contingencia:

| Modo de Prueba | Configuración del Dispositivo | Criterio de Aceptación |
| :--- | :--- | :--- |
| **Prueba A: Conectividad Total** | Wi-Fi ON / Datos Móviles ON | Adquisición GPS < 2s. Mapa carga desde PMTiles local (0 peticiones a CDN). Puntos visibles. |
| **Prueba B: Sin Internet Móvil** | Wi-Fi OFF / Datos Móviles OFF / GPS ON | GPS fija posición mediante hardware y efemérides en caché (< 10s). Routing A* calcula ruta. |
| **Prueba C: Aislamiento Total** | Modo Avión activado + GPS activado | Aplicación inicia sin conexión. Mapa renderiza fluidamente. Snapping y ruta peatonal operativos. |
| **Prueba D: Cold Start en Apagón** | Modo Avión + Teléfono reiniciado (sin caché GPS) a cielo abierto | El servicio no colapsa por timeout de 5s; espera la adquisición de satélites GNSS (30–60s) y fija ubicación. |

---

## 4. Matriz de Riesgos y Mitigaciones Técnicas

| Riesgo Técnico Identificado | Impacto | Mitigación Arquitectónica |
| :--- | :---: | :--- |
| **Puerto del servidor local en conflicto** | Alto | Usar puerto efímero asignado por el sistema operativo (`HttpServer.bind('127.0.0.1', 0)`). |
| **Consumo de memoria RAM en Dart por el grafo** | Medio | Utilizar formato binario empaquetado y listas tipadas (`Uint32List`), evitando instanciar 855k objetos Dart individuales. |
| **Glifos tipográficos ausentes en estilo offline** | Medio | Empaquetar fuentes Noto Sans en formato PBF en los assets locales de la app. |
| **Batería drenada por GPS continuo** | Medio | Configurar `distanceFilter: 5` metros y desactivar el stream de ubicación cuando la app pasa a segundo plano. |
