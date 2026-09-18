# AguaCION — Agua Segura Perú

**Plataforma Móvil y PWA de Misión Crítica para Navegación Offline hacia Puntos Oficiales de Abastecimiento de Agua en Lima y Callao ante Sismos de Gran Magnitud.**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart)](https://dart.dev)
[![PWA Live](https://img.shields.io/badge/PWA-Online%20%26%20Offline%20Ready-10b981?logo=pwa)](https://cionsunass01-ai.github.io/app-movil-sismo-v2/)
[![Zero External Dependencies](https://img.shields.io/badge/Network%20Calls-0%20(Offline%20Mode)-blue)](#)
[![Tests Passing](https://img.shields.io/badge/Tests-32%2F32%20Passing-success)](#)

---

## 🏛️ Contexto Institucional

**Contexto institucional: SUNASS** *(Superintendencia Nacional de Servicios de Saneamiento)*

> [!NOTE]
> Este desarrollo técnico y prototipo funcional se enmarca en la Gestión del Riesgo de Desastres (GRD). Los datos de puntos de abastecimiento provienen de los informes remitidos por SEDAPAL a SUNASS en el marco de las acciones de fiscalización y supervisión.

---

## 🌐 Aplicación Web Progresiva (PWA en Producción)

La aplicación se encuentra desplegada y disponible para su uso público en:

🔗 **[https://cionsunass01-ai.github.io/app-movil-sismo-v2/](https://cionsunass01-ai.github.io/app-movil-sismo-v2/)**

### ¿Cómo probar el funcionamiento 100% Offline en tu celular?
1. Abre el enlace en tu navegador móvil (Google Chrome en Android o Safari en iOS).
2. Espera a que la tarjeta de **Precarga de Cartografía Offline** descargue y guarde el mapa de Lima (10.6 MB) en la memoria interna del teléfono mediante IndexedDB (verás la barra de progreso fluida de 0% a 100%).
3. **Instala la PWA** tocando "Instalar" o mediante "Agregar a la pantalla de inicio".
4. **Activa el Modo Avión** en tu celular (desconectando Wi-Fi y datos móviles).
5. Abre la aplicación desde tu pantalla de inicio: **el mapa vectorial completo (calles, avenidas, ríos, distritos y puntos de agua) cargará y responderá de forma inmediata y 100% desconectada**.

---

## 🚀 Capacidades y Logros Técnicos

* **Cartografía Vectorial 100% Desconectada:** Renderizado por aceleración de hardware (WebGL en Web / Metal en iOS / Vulkan en Android) utilizando MapLibre y teselas vectoriales PMTiles (Zoom 0 a 14) de Lima Metropolitana y Callao.
* **Adaptador `LocalBlobSource` e IndexedDB en PWA:** Resuelve la incompatibilidad del estándar Cache API con peticiones de rango HTTP parciales (`206 Partial Content`), permitiendo que el navegador lea los tiles directamente de memoria local con cero llamadas de red en Modo Avión.
* **Almacenamiento Duradero:** Solicita persistencia de cuota en el navegador mediante `navigator.storage.persist()` para prevenir la purga automática por parte del sistema operativo en dispositivos con poco espacio.
* **Service Worker `sw.js` (Cache-First):** Pre-cachea el cascarón de la app, el motor CanvasKit, librerías locales, tipografías y datos oficiales.
* **Glifos Tipográficos Offline:** Atlas local PBF (`Noto Sans Regular` y `Noto Sans Bold`) para rotulación de calles con soporte completo de caracteres y diacríticos en español.
* **Grafo Peatonal Binario `AGUACSR1`:** Estructura en Memoria Comprimida por Filas (*Compressed Sparse Row*) que almacena 855,857 nodos y 1,990,320 aristas caminables con precisión submétrica (enteros Int32 en microgrados).
* **Algoritmo de Snapping en O(1):** Indexación espacial mediante cuadrícula de 275 metros (`EdgeSpatialGrid`) que proyecta al usuario a la red caminable más cercana.
* **Motor de Ruteo A\* Forward con Búsqueda Adaptativa:** `AdaptiveWaterPointSearch` calcula la ruta más corta a pie evaluando solo puntos geodésicamente plausibles, resolviendo rutas complejas en menos de 5 milisegundos.
* **Bloqueo Dinámico de Vías Colapsadas:** Permite al ciudadano reportar escombros o calles intransitables para recalcular un desvío alternativo de inmediato en memoria.
* **UX/UI Institucional de Nivel Estado:**
  - **Onboarding de Precarga Cartográfica:** Barra de progreso fluida de 0% a 100%, tipografía tabular e iconografía vectorial SVG (cero emojis informales).
  - **Modal Pedagógico de Ubicación (`LocationPermissionModal`):** Explica que la lectura GPS se procesa estrictamente en el dispositivo antes de invocar los permisos del sistema.
  - **Avisos Operacionales de 48 Horas:** Disclaimers transparentes que recuerdan que tras un sismo mayor, la confirmación física y presurización de las redes puede demorar hasta 48 horas mientras SEDAPAL inspecciona la infraestructura.

---

## 📱 Estructura del Código Fuente

```text
lib/
├── core/                  # Constantes, paleta institucional SUNASS y utilidades geodésicas
├── data/                  # Repositorios y normalización de los 433 puntos oficiales
├── domain/                # Entidades y reglas del modelo operacional desconectado
│   ├── audit/             # Trazabilidad y auditoría de eventos
│   ├── incident/          # Modelado de vías bloqueadas y escombros
│   ├── metadata/          # Versión y metadatos de los datasets
│   ├── recommendation/    # Modelos de selección de puntos viables
│   ├── reporting/         # Reportes ciudadanos locales (outbox idempotente)
│   ├── source/            # Confianza, frescura y fuentes oficiales
│   └── water/             # Estado de infraestructura y puntos de abastecimiento
├── presentation/          # Vistas de usuario, pestañas (IndexedStack) y modales
└── poc/                   # Motor de navegación offline
    └── offline_navigation/
        ├── graph/         # Grafo CSR en memoria y buffers binarios
        ├── models/        # Estructuras de datos para A* y snapping
        ├── presentation/  # Visor interactivo y telemetría de rendimiento
        ├── routing/       # Algoritmo A* y AdaptiveWaterPointSearch
        ├── services/      # Gestor PMTiles, servicio GNSS y adaptadores web
        └── spatial/       # Indexación espacial en grilla O(1)
web/
├── index.html             # Cascarón PWA con meta-tags iOS/Android y enlace de scripts locales
├── manifest.json          # Manifiesto PWA con nombres institucionales e iconos
├── maplibre-gl.js / .css  # Motor cartográfico local (sin dependencias de CDN externos)
├── pmtiles.js             # Librería base para el formato PMTiles
├── pmtiles_offline.js     # Adaptador IndexedDB LocalBlobSource y Onboarding SVG
└── sw.js                  # Service Worker Cache-First para soporte 100% desconectado
```

---

## 🛠️ Comandos de Desarrollo y Compilación

### Requisitos Previos
* Flutter SDK $\ge 3.24.0$ (recomendado 3.47.2 o superior)
* Dart SDK $\ge 3.12.0$

### 1. Análisis de Calidad y Pruebas Unitarias
```bash
# Obtener dependencias
flutter pub get

# Análisis estático sin advertencias (linter)
flutter analyze

# Ejecutar suite de pruebas unitarias
flutter test
```

### 2. Compilación y Despliegue Web (PWA)
```bash
# Compilar en modo release con base-href para GitHub Pages
flutter build web --base-href "/app-movil-sismo-v2/" --release

# Configurar worker offline
Copy-Item -Force build\web\sw.js build\web\flutter_service_worker.js
New-Item -ItemType File -Force -Path build\web\.nojekyll
```

### 3. Compilación Móvil Nativa
```bash
# Para Android (APK independiente)
flutter build apk --release

# Para iOS (Requiere macOS y Xcode)
flutter build ios --release --no-codesign
```

---

## 📚 Documentación Técnica Detallada

Para una comprensión exhaustiva de la arquitectura y decisiones de diseño, consulta:
* [Diseño de Arquitectura](documentacion/Diseño_de_Arquitectura.md)
* [Evaluación de Factibilidad PWA](documentacion/Evaluacion_Factibilidad_PWA.md)
* [Flujogramas de Operación](documentacion/Flujograma.md)
* [Estado Consolidado del Proyecto](docs/PROJECT_STATUS_AGUACION.md)
* [Especificaciones de Términos de Referencia (TDR)](docs/TDR.md)
