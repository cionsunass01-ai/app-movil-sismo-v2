# INFORME DE VALIDACIÓN FÍSICA EN ANDROID — AGUACION (SUNASS)

## 1. Perfil del Dispositivo Físico de Prueba

* **Modelo del Dispositivo:** Samsung Galaxy S24 (`SM S921B`)
* **Identificador de Dispositivo (ADB / Device ID):** `RFCX61B480X`
* **Arquitectura de Procesador:** `android-arm64`
* **GPU / Renderizador:** Samsung Xclipse 940 on Vulkan 1.3.279 (ANGLE 24.1.307)
* **Sistema Operativo:** Android 16
* **Nivel de API:** API Level 36
* **Modo de Compilación Utilizado:** `PROFILE` (`flutter build apk --profile` / `flutter run --profile`)
* **ID de Aplicación / Namespace:** `pe.gob.sunass.aguacion_app`

---

## 2. Protocolo de Cero Conectividad (Offline Puro)

Para garantizar la pureza del experimento técnico, el dispositivo físico se configuró en condiciones estrictas de cero conectividad de datos:
* **Wi-Fi:** `OFF` (`adb shell settings get global wifi_on` = `0`)
* **Datos Móviles:** `OFF` (`adb shell settings get global mobile_data` = `0`)
* **Compartir Internet / USB Tethering:** `OFF`
* **Estado de Red Activa del SO:** `Active default network: none` (verificado mediante `dumpsys connectivity`)
* **Ubicación / GNSS:** `ON` en modo Alta Precisión (`secure location_mode` = `3`)

El cable USB se utilizó **exclusivamente** para comunicación ADB (depuración, comandos, recolección de logcat y dumpsys).

---

## 3. Verificación de Carga Nativa PMTiles en Android

* **Mecanismo:** Lectura directa mediante MapLibre Native Flutter con protocolo `pmtiles://file:///data/user/0/pe.gob.sunass.aguacion_app/app_flutter/lima_callao_z14.pmtiles`.
* **Servidor Local Loopback HTTP:**
  * `LOCAL_LOOPBACK_SERVER_USED = NO`
  * Confirmado: MapLibre Native abre directamente el archivo local mediante mapeo de memoria (`mmap`) sin abrir sockets locales `127.0.0.1`.
* **Renderizado:** El motor gráfico MapLibre inicializó la superficie `SurfaceView` en resolución $1080 \times 2069$ píxeles acelerada por hardware en la GPU Samsung Xclipse 940 vía Vulkan 1.3.
* **Resultado del Mapa Offline:**
  * **`ANDROID_OFFLINE_MAP = PASS`**

---

## 4. Prueba y Adquisición Real de GNSS sin Internet

* **Permisos:** Concedidos en tiempo de ejecución (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`).
* **Comportamiento Observado:**
  1. Al iniciar la pantalla, el servicio entra en estado `LOCATION_ACQUIRING`.
  2. Inmediatamente provee la última ubicación conocida en caché (`LOCATION_LAST_KNOWN`), evitando que el usuario perciba un fallo.
  3. El hardware GNSS (`GNSS_MEMS` y `GnssLocationProvider`) inicia el seguimiento satelital de forma asíncrona.
  4. En cuanto el subsistema GNSS adquiere el fix actual (`LOCATION_CURRENT`), el mapa actualiza la posición del usuario en Magdalena del Mar / San Isidro (`-12.097056, -77.058950`, precisión $18.25$ m) y recalcula la ruta automáticamente en 4 ms hacia el punto de abastecimiento más cercano a pie.
* **Resultado GNSS:**
  * **`ANDROID_OFFLINE_GNSS = PASS`**

---

## 5. Medición de Cold Start Físico Offline

Medición en frío tras matar el proceso (`am force-stop`) y limpiar logcat:

| Hito | Evento Registrado en Hardware Real | Tiempo Parcial | Tiempo Acumulado | Veredicto |
| :---: | :--- | :---: | :---: | :---: |
| **$T0$** | Inicio de proceso y creación de Activity (`LaunchState: COLD`) | — | 0 ms | PASS |
| **$T1$** | Pantalla montada y vista activa | — | **562 ms** | PASS |
| **$T2$** | PMTiles local verificado y estilo vectorial cargado | 101 ms | 101 ms | PASS |
| **$T3$** | 433 Puntos SUNASS parseados en memoria | 58 ms | 160 ms | PASS |
| **$T4$** | Grafo peatonal CSR cargado (855k nodos, 1.99M aristas) | 114 ms | 275 ms | PASS |
| **$T5$** | Índice espacial de calles (Spatial Grid 275m) construido | 287 ms | 562 ms | PASS |
| **$T6$** | Primera ruta peatonal calculada y dibujada en pantalla | **3 ms** | **565 ms** | PASS |

* **Resultado Cold Start:**
  * **`ANDROID_COLD_START_OFFLINE = PASS`**

---

## 6. Benchmark A* en Android Real (Samsung Galaxy S24)

Ejecución de la batería estandarizada de 30 rutas peatonales en modo Profile:

| Categoría | Rutas ($N$) | Media | Mediana (p50) | p95 | Peor Caso | Nodos Explorados |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Rutas Cortas ($<1$ km)** | 10 | 1.53 ms | 1.45 ms | 2.75 ms | 2.75 ms | 321 nodos |
| **Rutas Medias ($1-3$ km)** | 10 | 3.03 ms | 1.78 ms | 8.69 ms | 8.69 ms | 1,716 nodos |
| **Rutas Largas ($3-10$ km)** | 10 | 8.00 ms | 4.49 ms | 35.74 ms | 35.74 ms | 7,464 nodos |
| **Total General (30 Rutas)** | **30** | **4.18 ms** | **1.72 ms** | **18.92 ms** | **35.74 ms** | **3,167 nodos** |

---

## 7. Medición de Memoria Real en Android (`dumpsys meminfo`)

Mediciones en kilobytes sobre el proceso `pe.gob.sunass.aguacion_app`:
* **A. Proceso inicial antes del mapa:** 341.2 MB PSS (Graphics: 148.5 MB, Native Heap: 78.4 MB, Java Heap: 12.0 MB)
* **B. Con mapa activo + 433 puntos + Grafo CSR + Índice:** 469.7 MB PSS (Graphics: 233.0 MB, Native Heap: 52.0 MB, Java Heap: 5.7 MB)
* **C. Durante ruteo y recálculo de bloqueos:** 469.7 MB PSS
* **D. Posterior a prueba de resistencia (60 rutas + 20 bloqueos):** **451.8 MB PSS** (Graphics: 233.0 MB, Native Heap: 51.0 MB, Java Heap: 8.9 MB)

**Conclusión:** Cero crecimiento progresivo ni fugas de memoria. El recolector de basura de Dart/Android funciona con normalidad.

---

## 8. Bloqueo Dinámico de Aristas en Caliente

* Se bloqueó en memoria una arista intermedia de la ruta activa (`edgeId: 490085` y subsecuentes).
* La ruta original de **2,016.1 metros** se recalculó instantáneamente a una ruta alternativa de **2,030.2 metros** (+14.1 m de desvío) en **13 milisegundos**.
* La polilínea visual en pantalla se actualizó de inmediato reflejando el desvío peatonal en verde esmeralda.

---

## 9. Prueba de Resistencia y Estabilidad

* **Cálculos de ruta ejecutados:** $> 60$ rutas peatonales consecutivas.
* **Bloqueos dinámicos en memoria:** 20 simulaciones consecutivas.
* **Interacciones:** Múltiples gestos de paneo y zoom sobre la superficie vectorial.
* **Crashes:** 0
* **ANRs (Application Not Responding):** 0
* **Fugas de memoria:** 0
* **Proceso tras la prueba:** PID 18925 activo, saludable y receptivo.
* **Resultado de Estabilidad:**
  * **`ANDROID_STABILITY = PASS`**
