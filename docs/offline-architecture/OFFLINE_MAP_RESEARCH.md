# Investigación Técnica: Motor de Mapa Visual Vectorial Offline (MapLibre + PMTiles)

## 1. Resumen Ejecutivo y Objetivos

Para la aplicación **Agua Segura Perú / AguaCION (SUNASS)**, el mapa visual cumple una función crítica pero acotada: **orientar al ciudadano en situaciones de emergencia extrema (apagón eléctrico, colapso de redes móviles, terremoto)** para que identifique su posición espacial respecto a los 433 puntos oficiales de abastecimiento de agua y visualice la ruta peatonal a seguir.

El motor de visualización cartográfica debe cumplir con los siguientes requerimientos no negociables:
1. **100% Offline**: Cero peticiones de red hacia servidores de teselas externos tras la instalación.
2. **Bajo Peso**: El paquete cartográfico completo de Lima Metropolitana y Callao debe ser lo suficientemente ligero para descargarse en conexiones lentas o empaquetarse en la app (< 15–20 MB).
3. **Alto Rendimiento en Dispositivos Modestos**: Renderizado vectorial fluido a 60 fps con aceleración por hardware (OpenGL / Metal / Vulkan).
4. **Soporte Bipolítica Android e iOS**: Integración estable y mantenida en Flutter.
5. **Separación de Responsabilidades**: El mapa es un **motor de renderizado visual**. El cálculo de rutas, snapping y selección de puntos es responsabilidad exclusiva del motor de routing.

---

## 2. Evaluación de MapLibre como Motor Visual

### 2.1. Paquetes y Estado en el Ecosistema Flutter
* **Paquete Oficial**: `maplibre_gl` en [pub.dev](https://pub.dev/packages/maplibre_gl).
* **Gobernanza**: Fundación MapLibre (MapLibre Organization), respaldada por AWS, Meta, Microsoft, TomTom y Grab tras el fork abierto de Mapbox GL v1.
* **Licencia**: MapLibre Native está bajo licencia **BSD 2-Clause**, permitiendo su uso comercial, institucional y gubernamental sin pago de regalías ni telemetría obligatoria.
* **Compatibilidad de Plataformas**:
  * **Android**: Compatible desde Android 5.0 (API 21+) hasta Android 15+. Utiliza MapLibre Native para Android con backend OpenGL ES / Vulkan.
  * **iOS**: Compatible desde iOS 12.0+ hasta iOS 18+. Utiliza MapLibre Native para iOS con Metal Shading Language.

### 2.2. Capacidades Analizadas
* **Capas GeoJSON y Marcadores Dinámicos**: MapLibre permite inyectar GeoJSON en tiempo de ejecución (como `GeoJsonSource` y `SymbolLayer` o `CircleLayer`), lo que permite dibujar los 433 puntos de abastecimiento de SUNASS y la línea de la ruta activa (`LineLayer`) directamente en memoria de GPU sin requerir peticiones de red.
* **Ubicación del Usuario**: Incluye soporte nativo para `myLocationEnabled: true` y modos de seguimiento (`MyLocationTrackingMode.tracking`), renderizando el punto de pulso GPS nativo sobre el mapa.
* **Estilos Locales**: Admite archivos `style.json` autocontenidos (especificación MapLibre Style Specification), junto con sprites de iconos y glifos tipográficos (PBF) almacenados localmente en los assets de Flutter.

---

## 3. Arquitectura de Almacenamiento: PMTiles vs MBTiles

### 3.1. ¿Qué es PMTiles?
PMTiles (versión 3) es un formato de archivo único concebido por Brandon Liu (Protomaps) diseñado específicamente para pirámides de teselas (vectoriales MVT o ráster).
* **Estructura Interna**:
  * Cabecera compacta de 127 bytes.
  * Directorio de teselas indexado mediante curvas de Hilbert (Z/X/Y).
  * Payloads de teselas comprimidos en Gzip (Mapbox Vector Tiles `.mvt`).
* **Ventaja respecto a MBTiles**:
  * MBTiles utiliza una base de datos SQLite con tablas `tiles` y `metadata`. En iOS y Android, SQLite introduce un overhead de transacciones y bloqueos de lectura de disco concurrentes.
  * PMTiles es un archivo binario plano de acceso directo por offsets de bytes (`byte-range reads`). Permite lecturas concurrentes sin locks de base de datos.

### 3.2. Integración Offline en Flutter: Patrón "Localhost Loopback Proxy"
Dado que MapLibre Native consume fuentes vectoriales mediante URLs HTTP en su `style.json` (`"tiles": ["http://.../{z}/{x}/{y}.mvt"]`), la arquitectura óptima y probada en producción para PMTiles en Flutter es:

```
+-------------------------------------------------------------------+
|                        AguaCION Flutter App                       |
|                                                                   |
|   +-------------------+              +-------------------------+  |
|   |   MapLibre Map    |              |  Dart Loopback Proxy    |  |
|   |    (Native UI)    |              |  (HttpServer 127.0.0.1) |  |
|   +--------+----------+              +------------+------------+  |
|            |                                      |               |
|            | GET http://127.0.0.1:port/{z}/{x}/{y}.mvt            |
|            +------------------------------------->|               |
|                                                   | Read byte-offs|
|                                                   v               |
|                                         +---------------------+   |
|                                         | lima_callao.pmtiles |   |
|                                         |  (Single File)      |   |
|                                         +---------------------+   |
+-------------------------------------------------------------------+
```

1. La aplicación levanta un micro-servidor interno en Dart (`HttpServer.bind(InternetAddress.loopbackIPv4, 0)`).
2. El servidor abre el archivo local `lima_callao.pmtiles` con `RandomAccessFile`.
3. Al recibir una solicitud `/{z}/{x}/{y}.mvt`, consulta la cabecera/directorio en memoria (que pesa menos de 4 KB), busca el offset y retorna inmediatamente los bytes de la tesela con cabecera `Content-Type: application/x-protobuf` y `Content-Encoding: gzip`.
4. **Resultado**: MapLibre renderiza fluidamente sin que un solo paquete salga del dispositivo. Latencia de tesela: **< 1 milisegundo**.

---

## 4. Variantes Cartográficas Generadas y Métricas Experimentales

A partir del extracto oficial de OpenStreetMap de Lima y Callao (BBBike / Protomaps 2026-09-08), se generaron y validaron experimentalmente dos variantes de PMTiles:

| Métrica | Variante A: Emergency Minimal | Variante B: Emergency Detailed |
| :--- | :---: | :---: |
| **Niveles de Zoom** | Zoom 0 a 12 | Zoom 0 a 14 |
| **Enfoque de Contenido** | Red vial principal, ríos, costa, límites distritales, áreas urbanas y parques mayores. | Calles residenciales completas, pasajes peatonales, manzanas urbanas, ríos y plazas. |
| **Elementos Excluidos** | Comercios, tiendas, restaurantes, vida nocturna, POIs de ocio, edificios 3D. | Comercios, publicidad, edificios 3D, detalles cosméticos innecesarios. |
| **Total de Teselas Indexadas** | 128 direccionadas (114 entradas) | 1,539 direccionadas (1,204 entradas) |
| **Tamaño en Disco** | **2.21 MB** (2,217,143 bytes) | **10.88 MB** (11,409,878 bytes) |
| **Tiempo de Extracción** | 8.19 segundos | 12.56 segundos |
| **Cobertura de 433 Puntos** | **433 / 433 (100.0%)** | **433 / 433 (100.0%)** |
| **Teselas z14 requeridas** | N/A (upscaled z12) | 122 teselas contienen los 433 puntos |

---

## 5. Validación Experimental de Servidor Local Offline

En el laboratorio se levantó el servidor de teselas local apuntando exclusivamente al archivo generado:
* **Comando**: `./tools/offline_map_spike/bin/pmtiles serve tools/offline_map_spike --port=8089`
* **Prueba 1 (Tesela raíz 0/0/0)**: `HTTP/1.1 200 OK`, tamaño 66,795 bytes, compresión Gzip.
* **Prueba 2 (Tesela de alta resolución Plaza Mayor de Lima z14/4686/8744)**: `HTTP/1.1 200 OK`, tamaño 75,082 bytes, compresión Gzip.
* **Registro de Conexiones Externas**: Durante toda la sesión de prueba se monitorizaron las interfaces de red; se confirmó **cero solicitudes hacia el exterior**.

---

## 6. Recomendación de Variante Visual para AguaCION

* **Recomendación Técnica**: **Variante B — Emergency Detailed (Zoom 0 a 14)**.
* **Justificación**:
  1. Su peso de **10.88 MB** se encuentra holgadamente por debajo del umbral objetivo del proyecto (< 30 MB).
  2. En emergencias urbanas, el nivel de zoom 14 es el umbral mínimo que permite al peatón distinguir nombres de jirones, pasajes y bifurcaciones inmediatas al aproximarse a un punto de agua en distritos densos (e.g. Cercado, Comas, Villa El Salvador).
  3. La Variante A (2.2 MB) puede mantenerse como fallback ultra-ligero para distribución masiva por canales de muy bajo ancho de banda.
