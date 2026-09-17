# TÉRMINOS DE REFERENCIA (TDR)

## 1. NOMBRE DEL PROYECTO
**AguaCION**: Aplicación móvil orientada a la navegación offline hacia puntos de abastecimiento de agua durante escenarios de emergencia (Sismos/Desastres).

## 2. ANTECEDENTES Y CONTEXTO INSTITUCIONAL
El presente proyecto se desarrolla en el marco de la **Gestión del Riesgo de Desastres (GRD)** con foco en la distribución de agua potable ante escenarios críticos (ej. sismos de gran magnitud). El desarrollo técnico se plantea como una prueba de concepto (POC) y prototipo funcional para la **Superintendencia Nacional de Servicios de Saneamiento (SUNASS)**, demostrando la viabilidad de una solución tecnológica resiliente a la caída de telecomunicaciones e internet.

> **Nota de Confidencialidad/Oficialidad:** Este repositorio constituye un desarrollo técnico y no debe considerarse una aplicación ni producto oficial de SUNASS sin su autorización expresa.

## 3. OBJETIVO GENERAL
Desarrollar, implementar y validar una aplicación móvil (Android e iOS) capaz de guiar a ciudadanos hacia puntos de abastecimiento de agua seguros más cercanos mediante un sistema de mapas y ruteo peatonal **100% offline**.

## 4. ALCANCE Y CARACTERÍSTICAS TÉCNICAS

### 4.1. Capacidades Core (Offline)
- **Mapas Vectoriales Locales:** Renderizado cartográfico usando MapLibre Native y teselas PMTiles, garantizando una carga rápida y de bajo consumo en memoria, sin requerir conexión a internet.
- **Ruteo Peatonal en Dispositivo:** Cálculo de rutas (camino más corto) mediante el motor de búsqueda A* con heurística geodésica Haversine, basado en un Grafo Peatonal Offline comprimido (CSR - Compressed Sparse Row).
- **Adquisición GNSS Nativa:** Uso de hardware satelital en el dispositivo (`geolocator`) para alta precisión geométrica y robustez ante cold-starts.
- **Búsqueda Inteligente:** Motor adaptativo (`AdaptiveWaterPointSearch`) con poda espacial que evalúa candidatos viables por proximidad geodésica antes de invocar el trazado del camino (A*).
- **Snapping Geométrico Conservador:** Vinculación algorítmica de la posición actual del usuario a la red vial usando un `EdgeSpatialGrid` en tiempo constante O(1).
- **Incidentes y Bloqueos:** Soporte para el bloqueo dinámico de aristas, permitiendo desviar el tráfico peatonal en caso de calles bloqueadas o zonas de colapso.

### 4.2. Especificaciones de Software y Arquitectura
El sistema adopta una **Clean Architecture** estructurada en las siguientes capas dentro del directorio `lib/`:
- **Core:** Tokens de diseño, constantes y servicios nativos.
- **Domain:** Modelo operacional fuertemente tipado. Incluye auditoría, bloqueo de incidencias, sistema de recomendación, reportes ciudadanos (idempotentes), fuentes y gestión del estado operativo de los puntos de agua.
- **Data:** Fuentes de datos, acceso a preferencias locales y transformaciones.
- **POC:** Lógica intensiva de navegación, manejo del grafo CSR, UI de MapLibre e indexación espacial.
- **Presentation:** Interfaz de usuario (UI/UX) bajo las guías de Material/Cupertino.

### 4.3. Stack Tecnológico
- **Framework:** Flutter (SDK `^3.12.2`)
- **Lenguaje:** Dart
- **Librerías principales:** 
  - `maplibre_gl` (Mapas offline)
  - `geolocator` (Ubicación por hardware)
  - `provider` (Inyección de dependencias y estado)
  - `shared_preferences`, `path_provider` (Almacenamiento local)
  - `connectivity_plus`, `share_plus`
- **Tipografía Local:** Google Fonts (Noto Sans) paquetizado vía offline atlas PBF.

## 5. FASES Y PLAN DE TRABAJO (HITOS)
El proyecto se ha estructurado en hitos incrementales:

- **Hito 1:** Auditoría y normalización de datos oficiales *(Completado)*.
- **Hito 2A:** Arquitectura offline base *(Completado)*.
- **Hito 2B:** Prueba de Concepto (POC) Flutter offline *(Completado)*.
- **Hito 2C:** Validación de rendimiento y uso físico en Android *(Completado)*.
- **Hito 2D:** Etiquetas offline, auditoría de accesos y validación en iOS *(Completado)*.
- **Hito 3A:** Modelo operacional de puntos de abastecimiento *(Completado)*.
- **Hito 3B:** Motor de recomendaciones operacionales *(Fase Pendiente/Por Iniciar)*.

## 6. REQUISITOS DE ENTREGABLES Y ACTIVOS (ASSETS)
Debido a regulaciones, algunos binarios no se exponen públicamente pero el sistema exige la capacidad de inyectarlos de forma segura:
1. Archivo Vectorial PMTiles (Lima-Callao, ~10 MB).
2. Grafo peatonal binario CSR (`.bin`, ~30 MB).
3. Datasets normalizados (`.json`/`.csv`) según validación institucional.
4. Código fuente completo documentado y protegido por linter (`flutter analyze`).
5. Pruebas unitarias/integración funcionales ejecutables vía `flutter test`.

> **Nota sobre Huella de Almacenamiento (Peso de la App):** Al ser una aplicación diseñada para operar 100% offline, los archivos estáticos mencionados (mapas, rutas y puntos) se incluyen en el instalador y se extraen en el almacenamiento interno del dispositivo tras la instalación. Por lo tanto, el peso total en un dispositivo (compilado en modo de producción/Release) se distribuye aproximadamente en: **~80 MB** correspondientes al motor optimizado de la aplicación y **~40-50 MB** correspondientes a los datos extraídos en caché (mapas y grafos). Se garantiza un consumo total cercano a los **~130 MB**, logrando total autonomía sin internet.

## 7. CONDICIONES DE ACEPTACIÓN
1. **Disponibilidad Offline Absoluta:** La app debe trazar una ruta hacia un punto de abastecimiento con 0 bytes de transferencia de red (modo avión activado).
2. **Rendimiento:** El cálculo de A* debe resolver rutas típicas (dentro de los 5 KM) en tiempos de CPU sub-segundo (< 15ms evidenciados).
3. **Estabilidad Multisistema:** Operatividad validada tanto en terminales Android modernos como en ecosistema iOS.

## 8. PROPIEDAD INTELECTUAL Y LICENCIAMIENTO
El código base es desarrollado explícitamente para propósitos de ayuda humanitaria y respuesta ante emergencias en Perú. Su distribución, uso operativo oficial o derivación están supeditados a los acuerdos institucionales vigentes (SUNASS y entidades competentes de la GRD).

### 8.1. Proveedores de Cartografía y Factibilidad Comercial
La cartografía incrustada en formato vector-tile (`.pmtiles`) deriva de los datos geográficos de **OpenStreetMap (OSM)**.
- **Cero Costos y Autonomía (Sin API Keys):** La aplicación no requiere ni utiliza "API Keys" comerciales (como Google Maps o Mapbox) ni se conecta a servidores de terceros, lo que elimina cualquier costo de consumo mensual y evita riesgos de filtración de cuotas.
- **Seguridad y Play Store:** Al no tener credenciales externas ni vulnerabilidades de red, la publicación en tiendas oficiales como la **Google Play Store** es 100% segura y factible. Asimismo, el tamaño de la aplicación instaladora optimizada (~80 MB) cumple holgadamente con los límites técnicos exigidos por las tiendas de distribución, siendo el único requisito legal mantener un texto de atribución a OpenStreetMap en los créditos de la app.
