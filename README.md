# AguaCION

Aplicación móvil Flutter orientada a navegación offline hacia puntos de abastecimiento de agua durante escenarios de emergencia.

---

## 🏛️ Contexto Institucional

**Contexto institucional: SUNASS**
*(Superintendencia Nacional de Servicios de Saneamiento)*

> [!NOTE]
> Este repositorio constituye un desarrollo técnico y prototipo funcional en el marco de la Gestión del Riesgo de Desastres (GRD). No debe considerarse una aplicación oficial ni producto oficial de SUNASS sin autorización institucional expresa.

---

## 📊 Estado del Proyecto

* **Hito 1** — Auditoría y normalización de datos oficiales: **COMPLETE**
* **Hito 2A** — Arquitectura offline: **COMPLETE**
* **Hito 2B** — POC Flutter offline: **COMPLETE**
* **Hito 2C** — Validación física Android: **COMPLETE**
* **Hito 2D** — Etiquetas offline, auditoría de accesos y validación física iOS: **COMPLETE**
* **Hito 3A** — Modelo operacional de puntos de abastecimiento: **COMPLETE**
* **Hito 3B** — Motor de recomendaciones operacionales: **NOT STARTED**

---

## 🚀 Capacidades Técnicas

* **Mapas vectoriales offline:** Renderizado cartográfico local mediante MapLibre Native con teselas vectoriales PMTiles y estilos geométricos locales.
* **Tipografías y glifos locales:** Atlas tipográfico PBF offline embebido (Noto Sans) con soporte completo para diacríticos y caracteres en español.
* **GNSS / ubicación en dispositivo:** Adquisición de posición satelital por hardware (`geolocator`) en primer plano, con medición de precisión métrica y tolerancia a cold-start.
* **Grafo peatonal offline (CSR):** Representación binaria comprimida *Compressed Sparse Row* de la red vial peatonal (Lima y Callao) optimizada para buffers contiguos `TypedData` (`Float64List` / `Int32List`).
* **Snapping conservador:** Vinculación espacial en O(1) vía `EdgeSpatialGrid` con umbral conservador de 50 metros.
* **Motor de búsqueda y ruteo A\*:** Cálculo de camino más corto peatonal en memoria con heurística geodésica Haversine.
* **Búsqueda adaptativa (`AdaptiveWaterPointSearch`):** Poda espacial inteligente que evalúa únicamente los candidatos viables según cota geodésica antes de ejecutar A\*.
* **Bloqueo dinámico de aristas:** Simulación y desvío de rutas ante interrupciones de vías o colapsos peatonales.
* **Cálculo de rutas peatonales:** Generación de ruta peatonal calculada según la información cartográfica y el grafo disponible, con estimación de distancia y tiempo a pie (~4 km/h).
* **Validación física en Android:** Demostrado en dispositivo físico (Samsung Galaxy S24) con cold-start sub-segundo y telemetría de ruteo <15 ms.
* **Validación física en iOS:** Demostrado en iPhone físico (iOS 18) con visualización de polilíneas, snapping a 50 m y estabilidad de memoria footprint.
* **Modelo operacional desacoplado:** Separación estricta entre la identidad estática de la infraestructura y el estado operativo dinámico, sin TTLs inventados ni umbrales rígidos no autorizados.

---

## 📦 Offline Assets y Datasets

Determinados datasets y binarios pesados offline no están incluidos directamente en este repositorio público mientras se define y aprueba institucionalmente su mecanismo de distribución y autorización oficial:

* **Mapa vectorial Lima-Callao (`.pmtiles`):** ~10.17 MB.
* **Grafo peatonal binario CSR (`.bin`):** ~30.67 MB.
* **Datasets de puntos normalizados oficiales (`.json`, `.csv`):** En proceso de revisión de publicación institucional (`PENDING_INSTITUTIONAL_APPROVAL`).

Para entornos de prueba y desarrollo local, estos artefactos pueden generarse o incorporarse en el directorio `assets/poc/` según los scripts reproducibles provistos en `tools/`.

---

## 📱 Estructura del Proyecto

```text
lib/
├── core/                  # Constantes, tokens de diseño y servicios de ubicación
├── data/                  # Repositorios y modelos base de la aplicación
├── domain/                # Hito 3A: Modelo operacional de dominio desacoplado
│   ├── audit/             # Registro de eventos operacionales
│   ├── incident/          # Bloqueos de aristas e incidencias
│   ├── metadata/          # Versión y metadatos de datasets
│   ├── recommendation/    # Modelos de candidatos y resultados de recomendación
│   ├── reporting/         # Reportes ciudadanos y outbox idempotente
│   ├── source/            # Confianza, frescura y políticas configurables
│   └── water/             # Puntos de abastecimiento y estado operativo
├── poc/                   # Hitos 2A-2D: Motor de navegación y mapas offline
│   └── offline_navigation/
│       ├── graph/         # Grafo CSR en memoria y buffers binarios
│       ├── presentation/  # UI del POC interactivo en MapLibre
│       ├── routing/       # Algoritmo A* y AdaptiveWaterPointSearch
│       ├── services/      # Servidor PMTiles local y servicio GNSS
│       └── spatial/       # Indexación espacial en grilla O(1)
└── presentation/          # Vistas, pantallas y widgets de la aplicación
```

---

## 🧪 Pruebas Automatizadas

Para validar la integridad del código, análisis estático y la suite completa de pruebas:

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Análisis estático (linter)
flutter analyze

# 3. Ejecutar suite de pruebas unitarias y de integración
flutter test
```

---

## 📄 Licencia

Código desarrollado para propósitos humanitarios y de gestión del riesgo de desastres ante sismos y emergencias en el Perú.
