# Agua Segura Perú — SUNASS 💧

**Red Cartográfica y Guía Ciudadana 100% Offline de Acceso a Agua Potable ante Emergencias y Desastres**

Desarrollado para la **Superintendencia Nacional de Servicios de Saneamiento (SUNASS)** y los ciudadanos de todo el Perú en el marco de la **Gestión del Riesgo de Desastres (GRD)**.

---

## 🎯 Propósito del Proyecto

Ante sismos de gran magnitud ($\ge 8.5\text{ Mw}$), huaicos o cortes masivos del servicio, las redes celulares y de internet suelen colapsar durante días mientras la infraestructura de agua sufre roturas. 

**Agua Segura Perú** transforma los Planes de Operaciones de Emergencia (POE) de las EPS en una herramienta móvil **100% Offline-First** que opera directamente con el chip GPS satelital del teléfono sin consumir datos:

* 📍 **Puntos de Abastecimiento:** Ubicación y distancia en tiempo real hacia camiones cisterna, piletas públicas de emergencia y pozos con grupo electrógeno.
* 🗺️ **Cartografía Vectorial Offline:** Rutas peatonales seguras de evacuación y mapa sin dependencia de Google Maps o Mapbox.
* ⏰ **Horarios de Racionamiento EPS:** Desglose transparente por sector de las horas de suministro durante la contingencia.
* 🧮 **Calculadoras Humanitarias:**
  * Reserva familiar basada en el **Estándar Esfera / OMS** ($15\text{ L/persona/día}$).
  * Dosificación exacta de cloración con lejía ($2\text{ mg/L}$) con cálculo de mL y gotas.
* 📡 **Reportes Ciudadanos (*Store & Forward*):** Registro de incidencias georreferenciadas con GPS que se guardan localmente y se transmiten automáticamente a SUNASS y COE EPS al recuperar la señal.

---

## 📁 Estructura del Repositorio

```
├── mobile/                  # Aplicación Móvil Oficial en Flutter (iOS & Android)
│   ├── lib/
│   │   ├── core/           # Tokens de diseño SUNASS, temas, utilidades Haversine y servicios
│   │   ├── data/           # Modelos de dominio, dataset y repositorio offline SharedPreferences
│   │   └── presentation/   # Vistas, controladores (Provider) y componentes UI
│   └── test/               # Pruebas unitarias, de estado y de widgets (100% passing)
├── src/                    # Prototipo / Demostrador Web interactivo original en React
├── docs/                   # Documentación y lineamientos de diseño (Frontend Design Skill)
└── package.json            # Configuración de herramientas web
```

---

## 🚀 Cómo Ejecutar la App Móvil (Flutter)

### Requisitos:
* Flutter SDK (3.x o superior)
* Xcode (para iOS) / Android Studio (para Android)

### Pasos:
```bash
# 1. Entrar al directorio de la app móvil
cd mobile

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar pruebas automatizadas
flutter test

# 4. Iniciar la aplicación
# En Simulador de iOS o Dispositivo:
flutter run

# En Navegador Web:
flutter run -d chrome
```

---

## 🏛️ Identidad Visual Institucional

El diseño sigue la paleta oficial de **SUNASS**:
* **Azul Institucional SUNASS (`#003876` / `#002244`)**
* **Celeste Gota SUNASS (`#00A3E0`)**
* **Verde Saneamiento / Agua Apta (`#00A859`)**
* **Rojo Semántico de Alerta Sísmica (`#DC2626`)**

---

## 📄 Licencia

Desarrollado con fines de servicio público y gestión de riesgo de desastres para el Perú.
