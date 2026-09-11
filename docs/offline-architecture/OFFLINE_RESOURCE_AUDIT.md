# AUDITORÍA DE RECURSOS OFFLINE — AGUACION (SUNASS)

## 1. Resumen Ejecutivo de la Auditoría

Conforme a lo exigido en la Sección 11 del Hito 2C, se realizó una auditoría estricta e independiente de todos los recursos cartográficos, de ruteo y datos utilizados por el POC de navegación offline de AguaCION en Flutter.

El objetivo fue verificar la ausencia absoluta de dependencias de red (`http://`, `https://`), comprobar que ningún recurso crítico intente conectarse a Internet durante la inicialización o navegación, y verificar que no se emplee ningún servidor HTTP localhost (loopback) para servir mapas locales.

---

## 2. Matriz de Auditoría de Recursos

| RECURSO | TIPO | LOCAL / REMOTE | UBICACIÓN EN EL DISPOSITIVO | REQUERIDO OFFLINE | DEPENDENCIAS DE RED | ESTADO DE AUDITORÍA |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Mapa Vectorial PMTiles** | Archivo vectorial z14 (10.17 MB) | **LOCAL** | Desempaquetado en almacenamiento privado (`/data/user/0/pe.gob.sunass.aguacion_app/app_flutter/lima_callao_z14.pmtiles`) | **SÍ (CRÍTICO)** | **NINGUNA** (acceso mmap nativo vía protocolo `pmtiles://file://`) | **AUDITADO Y APROBADO** |
| **Estilo Vectorial (Style JSON)** | JSON MapLibre v8 (2.2 KB) | **LOCAL** | Bundle de assets (`assets/poc/styles/emergency_geometric_style.json`) e inyección dinámica en memoria | **SÍ (CRÍTICO)** | **NINGUNA** (zero URLs http/https) | **AUDITADO Y APROBADO** |
| **433 Puntos SUNASS** | GeoJSON / JSON normalizado (818 KB) | **LOCAL** | Bundle de assets (`assets/poc/data/water_points_normalized.json`) | **SÍ (CRÍTICO)** | **NINGUNA** (cargado en memoria local) | **AUDITADO Y APROBADO** |
| **Grafo Peatonal CSR** | Binario AGUACSR1 (30.67 MB) | **LOCAL** | Bundle de assets (`assets/poc/routing/pedestrian_graph_lima_csr.bin`) | **SÍ (CRÍTICO)** | **NINGUNA** (leído vía ByteData/TypedData nativo) | **AUDITADO Y APROBADO** |
| **Índice Espacial de Calles** | Spatial Grid 275m en RAM | **LOCAL** | Estructura en memoria construida en caliente | **SÍ (CRÍTICO)** | **NINGUNA** | **AUDITADO Y APROBADO** |
| **Sprites / Iconos** | Simbología de puntos | **OMITIDO** | Capas geométricas vectoriales (`CircleLayer` y `LineLayer` MapLibre nativas) | NO (en POC) | **NINGUNA** | **AUDITADO Y APROBADO** |
| **Glyphs / Fuentes PBF** | Fuentes para etiquetas | **OMITIDO** | Omitido en este hito (`OFFLINE_LABELS_WORKING = NO`). No se incluyen URLs de fuentes remotas. | NO (para POC técnico) | **NINGUNA** | **AUDITADO Y APROBADO** |
| **Servicio de Servidor Local** | Microservidor HTTP loopback | **NO USADO** | No existe servidor HTTP local (`LOCAL_LOOPBACK_SERVER_USED = NO`) | NO | **NINGUNA** | **AUDITADO Y APROBADO** |

---

## 3. Verificación de Cero URLs Externas

Se realizó un escaneo automatizado en todo el árbol de código y assets del POC buscando cualquier prefijo `http://` o `https://`:

```bash
grep -ri "http://" assets/poc/ lib/poc/
grep -ri "https://" assets/poc/ lib/poc/
```

**Resultado:**
- En `assets/poc/styles/emergency_geometric_style.json`: CERO referencias a `http://` o `https://`.
- En `lib/poc/offline_navigation/`: CERO peticiones HTTP.
- Toda la comunicación de teselas utiliza exclusivamente el esquema nativo:
  `pmtiles://file:///data/user/0/pe.gob.sunass.aguacion_app/app_flutter/lima_callao_z14.pmtiles`

---

## 4. Estado de Local Loopback Server

* `LOCAL_LOOPBACK_SERVER_USED = NO`

MapLibre Native en Android (v11.7.0+) soporta de forma nativa el protocolo `pmtiles://file://` abriendo el archivo local mediante mapeo de memoria (`mmap`) con soporte HTTP Range emulation en C++. No se requiere abrir puertos TCP locales (`127.0.0.1`), evitando problemas de seguridad, consumo de sockets y posibles bloqueos de políticas de red en Android.

---

## 5. Dictamen sobre Etiquetas (Glyphs)

* `OFFLINE_LABELS_WORKING = NO`
* `BLOCKER_FOR_CITIZEN_PILOT = YES`
* `BLOCKER_FOR_ARCHITECTURAL_POC = NO`

Para este POC técnico arquitectural se mantuvieron deliberadamente omitidos los glifos PBF para evitar cualquier descarga accidental a MapTiler/OSM fonts. La orientación en el POC se realiza mediante la geometría vial, hidrografía, áreas verdes y los marcadores identificados de SUNASS. El paquete de glifos offline se integrará en un hito dedicado previo al despliegue ciudadano.
