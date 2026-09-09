# Agua Segura Perú — SUNASS 💧

**Aplicación Móvil 100% Offline de Cartografía y Guía Ciudadana de Acceso a Agua Potable ante Emergencias y Desastres**

Desarrollada en **Flutter** para la **Superintendencia Nacional de Servicios de Saneamiento (SUNASS)** y los ciudadanos de todo el Perú en el marco de la **Gestión del Riesgo de Desastres (GRD)**.

---

## 🎯 Propósito del Proyecto

Ante sismos de gran magnitud ($\ge 8.5\text{ Mw}$), huaicos o cortes masivos del servicio, las redes celulares e internet colapsan durante días mientras la infraestructura de tuberías sufre roturas. 

**Agua Segura Perú** es una herramienta móvil nativa **100% Offline-First** que opera directamente con el sensor GPS satelital del teléfono sin consumir datos:

* 📍 **Directorio Inteligente de Puntos de Agua:** Ubicación, estado operativo y distancia en tiempo real (Haversine) hacia cisternas, piletas públicas y surtidores/pozos con generador.
* 🗺️ **Cartografía Vectorial Offline:** Rutas peatonales seguras de evacuación y mapa interactivo en Canvas sin requerir conexión a internet.
* ⏰ **Horarios de Racionamiento EPS:** Desglose transparente por sector de las horas de suministro durante la contingencia.
* 🧮 **Calculadoras Humanitarias:**
  * Reserva familiar basada en el **Estándar Esfera / OMS** ($15\text{ L/persona/día}$ vs $7.5\text{ L/día}$ mínimo vital).
  * Dosificación de cloración con lejía comercial ($2\text{ mg/L}$) con cálculo de mL y gotas, y copiado de protocolo.
* 📡 **Reportes Ciudadanos (*Store & Forward*):** Registro de incidencias georreferenciadas que se guardan en memoria local y se transmiten automáticamente a SUNASS y COE EPS al recuperar la señal.

---

## 📱 Estructura del Proyecto Flutter

```
lib/
├── core/
│   ├── constants/        # Tokens de diseño SUNASS, colores y estándares humanitarios
│   ├── services/         # GPS nativo (Geolocator), alertas sonoras y hápticas
│   ├── theme/            # Tema visual Material 3 con Plus Jakarta Sans
│   └── utils/            # Cálculo de distancias Haversine y tiempos a pie
├── data/
│   ├── models/           # Modelos WaterPoint, SectorData, CitizenReport, UserLocation
│   ├── repositories/     # Repositorio con persistencia local en SharedPreferences
│   └── sources/          # Dataset simulado validado (Moquegua / Perú)
├── presentation/
│   ├── providers/        # Gestor de estado global reactivo (AppStateProvider)
│   ├── screens/
│   │   ├── points/       # Directorio de puntos y Ficha Técnica Modal
│   │   ├── map/          # Mapa vectorial interactivo en Canvas con ruta a pie
│   │   ├── sector/       # Horarios de racionamiento y comparativa EPS
│   │   ├── safe_water/   # Calculadoras de reserva familiar y cloración
│   │   ├── report/       # Formulario y bandeja de reportes offline
│   │   └── main_screen.dart # Estructura principal y barra de navegación
│   └── widgets/          # Cabecera SUNASS, barra de estado de red y alertas
└── main.dart             # Punto de entrada de la aplicación
```

---

## 🚀 Cómo Ejecutar la Aplicación

### Requisitos:
* [Flutter SDK](https://flutter.dev) (v3.x o superior)
* Xcode (para iOS) / Android Studio (para Android)

### Pasos:
```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar pruebas automatizadas
flutter test

# 3. Iniciar la aplicación
# En Simulador de iOS o dispositivo físico:
flutter run

# En Navegador Web:
flutter run -d chrome

# En macOS Desktop:
flutter run -d macos
```

---

## 🧪 Pruebas Automatizadas

El proyecto cuenta con una suite completa de pruebas unitarias, de estado y de widgets:

```bash
flutter test
```

* `geo_utils_test.dart`: Verificación matemática de la fórmula Haversine y tiempos de caminata.
* `app_state_provider_test.dart`: Pruebas de cambio de estado de sismo, conexión y encolado offline *Store & Forward*.
* `widget_test.dart`: Prueba de renderizado de la interfaz y navegación de pestañas.

---

## 🏛️ Identidad Visual Institucional

El diseño sigue la paleta oficial de **SUNASS**:
* **Azul Institucional SUNASS (`#003876` / `#002244`)**
* **Celeste Gota SUNASS (`#00A3E0`)**
* **Verde Saneamiento / Agua Apta (`#00A859`)**
* **Rojo Semántico de Alerta Sísmica (`#DC2626`)**

---

## 📄 Licencia

Desarrollado con fines de servicio público y gestión del riesgo de desastres para el Perú.
