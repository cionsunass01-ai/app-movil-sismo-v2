# Auditoría Integral del Dataset Oficial de Puntos Provisionales de Abastecimiento Fijo de Agua Potable (Lima Metropolitana y Callao)

**Proyecto:** Agua Segura Perú / AguaCION — SUNASS
**Versión del Informe:** 2.0.0 (Cierre de Auditoría — Capa Territorial Canónica Oficial INEI)
**Fecha:** 10 de septiembre de 2026
**Fuentes Oficiales Analizadas:**
- `Abastecimiento_Lima_metro.xlsx` (Dataset consolidado de 433 puntos, SEDAPAL corte agosto 2026, SHA-256: `f5547afba56b52c1816369a593419ae50d73ea9bf54ce265eb4cc18a293fbe5c`)
- `CARTA 1089.pdf` (Carta N° 1089-2026-GG de SEDAPAL a SUNASS, 19/08/2026, SHA-256: `2f82a7909684566e214250882d1a8239efe967d2b2a38752bbbb05d3201113cf`)
- `INFORME N° 052-2026-EOMR-SJL.pdf` (Informe técnico consolidado de los 7 EOMR de SEDAPAL, 19/08/2026, SHA-256: `dd8e06572d162c73253b5ae82e8cee0ee380cd577635675feb9db32ef8a4efc2`)
- `Distrito.rar` / `DISTRITO.gpkg` (Capa Oficial Distrital 2023 del Portal IDE del INEI, descargada directamente desde `https://ide.inei.gob.pe/files/Distrito.rar`)

---

## 1. Resumen Ejecutivo

La presente auditoría técnica y geoespacial examinó la totalidad de los **433 puntos provisionales de abastecimiento fijo de agua potable** consignados oficialmente por SEDAPAL para Lima Metropolitana y Callao en respuesta al requerimiento de fiscalización de SUNASS (Oficio N° 01278-2026-SUNASS-DF-SOEP).

### Hallazgos Principales:
1. **Volumen de datos y consistencia cuantitativa:** El archivo Excel registra exactamente 433 puntos, coincidiendo al 100% con el consolidado reportado en el Informe N° 052-2026-EOMR-SJL y la Carta N° 1089-2026-GG por los 7 Equipos de Operación y Mantenimiento de Redes (EOMR).
2. **Inestabilidad del Identificador Original (`Nombre o C`):** El campo no es único. Se detectó 1 registro sin nombre (`FID 24` en San Juan de Lurigancho), 15 registros con el nombre genérico `"ATARJEA"` (la totalidad de Villa El Salvador), y 10 registros con códigos duplicados en Ate Vitarte (`R-P1` a `R-P5`). Por tanto, este campo no puede utilizarse como clave primaria en la base de datos de AguaCION.
3. **Calidad de Coordenadas:** Las coordenadas geográficas (`POINT_X`, `POINT_Y`) y proyectadas (`UTM_E`, `UTM_N` en WGS 84 / UTM Zona 18S, EPSG:32718) son extraordinariamente consistentes entre sí. La discrepancia media calculada mediante proyección matemática inversa es de apenas **2.9 cm** y la máxima de **7.4 cm**, atribuible exclusivamente al redondeo a dos decimales de las coordenadas UTM oficiales. No existen coordenadas nulas, ni puntos `(0,0)`, ni puntos fuera de Lima y Callao.
4. **Indeterminación Crítica de `Capacidad`:** El campo presenta valores numéricos (principalmente `15.00` en 303 puntos, `2.00` en 89 puntos y `8.60` en 38 puntos), pero **ni el Excel ni los informes oficiales especifican la unidad de medida** (¿litros/segundo de caudal?, ¿m³/hora?, ¿volumen total en m³?). Se clasificó formalmente como `capacity_unit = UNKNOWN` para evitar falsas asunciones que afecten el cálculo de autonomía ciudadana.
5. **Divergencia entre `Situación` y `Estado`:** Ambos campos reflejan clasificaciones cuyas definiciones institucionales exactas no están documentadas en el expediente. Se comprobó aritméticamente que existen **111 puntos con `Situación = Operativo` y `Estado = En reserva`** (32 en Callao y 79 en Comas; en Comas existe además 1 punto `En reparación` con estado `En reserva`, totalizando 80 puntos en reserva). Asimismo, existen 8 puntos con `Situación = En implementación` y `Estado = Activo` en SJL. La semántica de ambos campos queda registrada como `PENDING_INSTITUTIONAL_DEFINITION` y no se deriva de ellos ninguna disponibilidad automática para el ciudadano.
6. **Brecha Territorial e Integración con Fuente Oficial INEI:** Mediante geoprocesamiento (*Point-in-Polygon* contra la capa oficial **Distrital (Actualizado al 2023)** del Portal IDE del INEI), se determinó que los 433 puntos cubren **36 distritos** de Lima y Callao y se asignaron al 100% sus códigos oficiales UBIGEO de 6 dígitos. Existen **14 distritos sin puntos provisionales fijos dentro de sus límites** según el dataset analizado. La estrategia de abastecimiento aplicable a estos distritos —uso de puntos en distritos vecinos, cisternas, puntos temporales u otras modalidades— requiere validación institucional.

---

## 2. Documentos Oficiales Inspeccionados

| Documento / Recurso | Procedencia | Fecha / Versión | Hash SHA-256 | Rol en el Proyecto |
| :--- | :--- | :--- | :--- | :--- |
| `Abastecimiento_Lima_metro.xlsx` | SEDAPAL (Consolidado EOMR) | 19/08/2026 | `f5547afba56b52c1...` | Dataset oficial de 433 puntos provisto a SUNASS. |
| `CARTA 1089.pdf` | SEDAPAL $\rightarrow$ SUNASS | 19/08/2026 | `2f82a7909684566e...` | Carta formal de entrega institucional. |
| `INFORME N° 052-2026-EOMR-SJL.pdf` | EOMR SJL $\rightarrow$ Gerencia Centro | 19/08/2026 | `dd8e06572d162c73...` | Informe de consolidación de los 7 EOMR. |
| `Distrito.rar` / `DISTRITO.gpkg` | Portal IDE INEI (`https://ide.inei.gob.pe/`) | Actualizado al 2023 | RAR: `ae224280...`<br/>GPKG: `b4b6485e...` | **Fuente territorial canónica oficial del Estado Peruano.** |
| `inei_lima_callao_distritos.geojson` | Derivado directo de `DISTRITO.gpkg` | 10/09/2026 | `31f74ce60f2d...` | Capa vectorial procesada con 50 distritos y UBIGEO. |

---

## 3. Estado del Repositorio AguaCION (Datos Geográficos)

Inspección de la arquitectura preexistente del proyecto Flutter:
- **Datos Mocks:** En [`mock_water_points.dart`](lib/data/sources/mock_water_points.dart) existen 10 puntos de abastecimiento y 5 ubicaciones simuladas para Moquegua.
- **Modelos:** En [`water_point.dart`](lib/data/models/water_point.dart), [`sector_data.dart`](lib/data/models/sector_data.dart), [`citizen_report.dart`](lib/data/models/citizen_report.dart) y [`user_location.dart`](lib/data/models/user_location.dart).
- **Repositorio:** [`water_repository.dart`](lib/data/repositories/water_repository.dart) maneja en memoria los puntos mock y persiste reportes ciudadanos mediante `SharedPreferences`.
- **Servicio GNSS/GPS:** [`location_service.dart`](lib/core/services/location_service.dart) implementa `geolocator` nativo para consultar coordenadas del dispositivo.
- **Lógica Matemática Haversine:** [`geo_utils.dart`](lib/core/utils/geo_utils.dart) implementa el cálculo de distancia ortodrómica y estimación de tiempo a pie ($4.0\text{ km/h}$).
- **Componentes de Mapa:** [`vector_map_painter.dart`](lib/presentation/screens/map/widgets/vector_map_painter.dart) dibuja en Canvas 2D los puntos relativos a la ubicación del usuario.

*Reutilización:* [`geo_utils.dart`](lib/core/utils/geo_utils.dart) y [`location_service.dart`](lib/core/services/location_service.dart) son 100% compatibles con Lima y Callao. El código funcional de Flutter no ha sido alterado en este hito.

---

## 4. Auditoría Estructural y Estadística del Excel

El archivo contiene una única hoja denominada `"Hoja 1"` con dimensiones `A1:O434` (1 fila de encabezado y 433 filas de datos).

| Campo original | Tipo detectado | Nulos | Valores únicos | Ejemplos | Observaciones |
| :--- | :--- | ---: | ---: | :--- | :--- |
| `FID` | `int64` | 0 | 433 | `0`, `1`, `432` | Índice secuencial de exportación shapefile (0 a 432). No es clave primaria institucional. |
| `Shape *` | `object` (string) | 0 | 1 | `'Point'` | Tipo de geometría de la capa GIS (todos son puntos). |
| `EOMR` | `object` (string) | 0 | 7 | `'EOMR-SJL'`, `'EOMR-Comas'` | Identificador del Equipo de Operación y Mantenimiento de Redes de SEDAPAL. |
| `Nombre o C` | `object` (string) | **1** | 413 | `'P.109'`, `'CR-230'`, `NaN` | **Campo truncado ("Nombre o Código"). Presenta 1 nulo y múltiples duplicados.** |
| `Tipo de co` | `object` (string) | 0 | 10 | `'Hidrante'`, `'Pozo'`, `'Sector'` | **Campo truncado ("Tipo de componente"). Mezcla interfaz ciudadana e infraestructura.** |
| `Ubicación` | `object` (string) | 0 | 418 | `'Jr Trujillo y Jr Arequipa'`, `'Las Terrazas del Pueblo'` | Descripción textual de la dirección. 20 registros comparten textos idénticos. |
| `Capacidad` | `float64` | 0 | 6 | `15.0`, `2.0`, `8.6`, `15.55` | **Sin unidad documentada.** 303 registros tienen exactamente 15.00. |
| `Situación` | `object` (string) | 0 | 4 | `'Operativo'`, `'Reserva'`, `'En implementación'` | Clasificación física del activo. Semántica pendiente de validación institucional. |
| `Estado` | `object` (string) | 0 | 2 | `'Activo'`, `'En reserva'` | Clasificación operativa. Semántica pendiente de validación institucional. |
| `Cuenta con` | `object` (string) | 0 | 4 | `'No'`, `'No corresponde'`, `'NO'`, `'Sí'` | **Campo truncado ("Cuenta con grupo electrógeno"). Inconsistencia de mayúsculas ("NO").** |
| `Otros` | `object` (string) | 0 | 55 | `'Pozo'`, `'MANIFOLDS'`, `'HIDRANTE'` | Información complementaria técnica (fuente de agua, código de pozo o dispositivo). |
| `POINT_X` | `float64` | 0 | 433 | `-77.013930`, `-76.960115` | Longitud geográfica WGS 84 (grados decimales). Rango: [-77.160908, -76.772472]. |
| `POINT_Y` | `float64` | 0 | 432 | `-12.027287`, `-12.021608` | Latitud geográfica WGS 84 (grados decimales). Dos filas comparten latitud por azar. |
| `UTM_N` | `float64` | 0 | 433 | `8669625.87`, `8670339.89` | Coordenada UTM Norte (metros, WGS 84 Zona 18S). Rango: [8646619.24, 8692720.36]. |
| `UTM_E` | `float64` | 0 | 433 | `280746.01`, `286602.08` | Coordenada UTM Este (metros, WGS 84 Zona 18S). Rango: [264774.43, 307087.28]. |

---

## 5. Auditoría de Identificadores y Duplicados

Se comprobó la hipótesis inicial: **el campo `Nombre o C` NO es apto como identificador único.**

### Casos Problemáticos Específicos:
1. **Registro con Valor Nulo (`NaN`):**
   - **FID 24:** `EOMR-SJL`, `Tipo de co: Pozo`, `Ubicación: Av. Principal y Ca 8, Lotización Campoy`, `Otros: HIDRANTE`, `Coords: (-12.021216, -76.960115)`. No posee ningún código o nombre en la fuente original.
2. **Nombre Genérico Masivo `"ATARJEA"` (15 registros):**
   - En **EOMR-Villa El Salvador**, las 15 filas tienen `Nombre o C = "ATARJEA"`, a pesar de ser 15 puntos físicos distintos en Villa El Salvador, San Juan de Miraflores y Villa María del Triunfo (FIDs 418 a 432).
3. **Códigos Duplicados en Ate Vitarte (10 registros):**
   - `R-P1`: Presente en FID 262 (Ca. El Manto) y FID 263 (Señor de Huayllay).
   - `R-P2`: Presente en FID 264 (Andrés A. Cáceres) y FID 265 (Corazón de Jesús).
   - `R-P3`: Presente en FID 266 (Las Violetas) y FID 267 (Nueva Villa La Campiña).
   - `R-P4`: Presente en FID 268 (Las Terrazas del Pueblo) y FID 269 (Villa Hermosa).
   - `R-P5`: Presente en FID 270 (Las Terrazas del Pueblo) y FID 271 (Los Jardines).
4. **Duplicidad de Coordenadas:**
   - Cero duplicados en pares `(POINT_X, POINT_Y)`. Las 433 ubicaciones son espacialmente distintas.
5. **Direcciones Textuales Compartidas (`Ubicación`):**
   - 20 filas comparten texto de dirección idéntico (e.g. 7 pozos en SJL registran `"VIA RAMIRO PRIALE HUACHIPA"`, 6 pozos en Ate `"Jr. San Pablo S/N Fundo La Encalada"`).

---

## 6. Análisis de Tipos de Componentes

### Catálogo Neutral Normalizado:

| Tipo de Componente Raw | Cantidad | Porcentaje | Normalización Sintáctica Neutral | Observaciones |
| :--- | ---: | ---: | :--- | :--- |
| `Hidrante` | 339 | 78.29% | `HIDRANTE` | Grifo contra incendios / hidrante en vía pública |
| `Pozo` | 36 | 8.31% | `POZO` | Pozo de extracción de agua subterránea |
| `Cámara de rebombeo` | 25 | 5.77% | `CAMARA_REBOMBEO` | Estación de bombeo / rebombeo de red |
| `GRIFO AMARILLO` | 15 | 3.46% | `GRIFO_AMARILLO` | Denominación local exclusiva de EOMR-VES |
| `Sector` | 12 | 2.77% | `SECTOR` | Componente de sectorización hidráulica |
| `Surtidor` | 2 | 0.46% | `SURTIDOR` | Surtidor de llenado de camiones cisterna |
| `Cámara de bombeo` | 1 | 0.23% | `CAMARA_BOMBEO` | Infraestructura de impulsión de agua |
| `Cámara SCADA` | 1 | 0.23% | `CAMARA_SCADA` | Cámara de telemetría y control |
| `Cámara de derivación` | 1 | 0.23% | `CAMARA_DERIVACION` | Cámara de bifurcación de red matriz |
| `Reservorio` | 1 | 0.23% | `RESERVORIO` | Estructura de almacenamiento de agua |
| **TOTAL** | **433** | **100.00%** | | |

*Nota:* Se mantiene la denominación sintáctica neutral en mayúsculas sin interpolar interpretaciones funcionales no documentadas.

---

## 7. Validación Técnica de Coordenadas

### Bounding Box del Dataset:
- **Latitud (POINT_Y):** `-12.235877` a `-11.818060`
- **Longitud (POINT_X):** `-77.160908` a `-76.772472`
- **UTM Este (m):** `264774.43` a `307087.28`
- **UTM Norte (m):** `8646619.24` a `8692720.36`

### Consistencia Matemática WGS 84 / UTM Zona 18S (EPSG:32718):
- **Error medio:** $0.0299\text{ metros}$ (~3.0 cm)
- **Error máximo:** $0.0745\text{ metros}$ (~7.4 cm en FID 406)
- **Desviación estándar:** $0.0221\text{ metros}$

---

## 8. Análisis de Capacidad

### Distribución de Valores:
- **`15.00`:** 303 puntos (69.98%) — Comas (140), Surquillo (61), SJL (42), Breña (32), VES (15), Ate Vitarte (13).
- **`2.00`:** 89 puntos (20.55%) — Todos en Ate Vitarte (hidrantes).
- **`8.60`:** 38 puntos (8.78%) — Todos en Callao (hidrantes).
- **`15.55`:** 1 punto (0.23%) — Callao (Surtidor Colonial).
- **`62.22`:** 1 punto (0.23%) — Callao (Surtidor Los Materiales).
- **`26.00`:** 1 punto (0.23%) — Ate Vitarte (Hidrante S002).

**Unidad de medida no documentada:** Ni el archivo Excel ni los informes oficiales mencionan la unidad física. Se mantiene `capacity_unit = UNKNOWN`.

---

## 9. Recálculo y Matriz de `Situación` y `Estado`

### Matriz Cruzada Global:

| Situación (Raw) | Estado = `Activo` | Estado = `En reserva` | TOTAL |
| :--- | ---: | ---: | ---: |
| **`Operativo`** | **304** | **111** | **415** |
| **`Reserva`** | 0 | **9** | **9** |
| **`En implementación`** | **8** | 0 | **8** |
| **`En reparación`** | 0 | **1** | **1** |
| **TOTAL** | **312** | **121** | **433** |

### Desglose Exacto del Cruce `Operativo` + `En reserva` (111 Puntos):
- **EOMR-Comas:** **79 puntos** (los otros 60 son `Operativo` + `Activo`, y 1 es `En reparación` + `En reserva`, totalizando 80 puntos `En reserva` y 140 puntos en Comas).
- **EOMR-Callao:** **32 puntos** (los otros 8 son `Operativo` + `Activo`, totalizando 40 puntos en Callao).
- **Total:** $79 + 32 = \mathbf{111\text{ puntos}}$.

*Aclaración Institucional:* Ambos campos quedan registrados con la etiqueta `situation_status_semantics = PENDING_INSTITUTIONAL_DEFINITION`. En esta fase no se deduce disponibilidad ciudadana (`available_to_citizen`) a partir de ellos.

---

## 10. Disponibilidad de Grupo Electrógeno (`Cuenta con`)

| Valor Raw | Cantidad | % | Normalizado | Justificación |
| :--- | ---: | ---: | :--- | :--- |
| `No` | 343 | 79.21% | `NO` | No cuenta con grupo electrógeno propio. |
| `No corresponde` | 64 | 14.78% | `NOT_APPLICABLE` | Hidrantes de red directa o componentes que no requieren bombeo autónomo. |
| `NO` | 15 | 3.46% | `NO` | Variación en mayúsculas en los 15 registros de Villa El Salvador. |
| `Sí` | 11 | 2.54% | `YES` | Cuenta con generador para operar en apagón masivo (9 en Comas, 2 en Ate). |
| **TOTAL** | **433** | **100.00%** | | |

---

## 11. Distribución Territorial por EOMR

Confrontación con el cuadro consolidado del `Informe N° 052-2026-EOMR-SJL`:

| EOMR Responsable | Total Oficial Informe | Total en Excel | Coincidencia |
| :--- | ---: | ---: | :---: |
| EOMR-Comas | 140 | 140 | Exacta (100%) |
| EOMR-Ate Vitarte | 103 | 103 | Exacta (100%) |
| EOMR-Surquillo | 61 | 61 | Exacta (100%) |
| EOMR-SJL | 42 | 42 | Exacta (100%) |
| EOMR-Callao | 40 | 40 | Exacta (100%) |
| EOMR-Breña | 32 | 32 | Exacta (100%) |
| EOMR-Villa El Salvador | 15 | 15 | Exacta (100%) |
| **TOTAL** | **433** | **433** | **Exacta (100%)** |

---

## 12. Fuente Territorial Oficial INEI y Asignación Distrital

### Ficha Técnica de la Fuente Cartográfica Oficial:
- **Organismo Productor:** **Instituto Nacional de Estadística e Informática (INEI)**.
- **Portal Oficial:** Infraestructura de Datos Espaciales del INEI (`https://ide.inei.gob.pe/`).
- **Nombre Oficial del Dataset:** Capa Distrital (Actualizado al 2023).
- **URL Exacta de Descarga:** `https://ide.inei.gob.pe/files/Distrito.rar`
- **Archivo Fuente Local:** `tools/data_audit/Distrito.rar` (SHA-256: `ae22428029000d801b3d68afd0914ba94ca40a789a9b56231f6131a75abb9654`).
- **GeoPackage Extraído:** `tools/data_audit/DISTRITO.gpkg` (SHA-256: `b4b6485e4161ce4413bf118f39411071f7627d979a4c271acb35103f1d3e2756`).
- **Capa Exportada:** `tools/data_audit/inei_lima_callao_distritos.geojson` (SHA-256: `31f74ce60f2d163b515c0bd3fbcfc3d278e8a48162799b48c9bce3ff75c2c367`).
- **CRS Original y de Geoprocesamiento:** EPSG:4326 (WGS 84 en grados decimales).
- **Atributos Oficiales Incorporados:** `ccdd` (department_code), `ccpp` (province_code), `ccdi` (district_code), `ubigeo` (district_ubigeo), `nombdist` (district), `nombprov` (province), `nombdep` (department), `fuente`.

### Comparación entre Fuente Anterior (GitHub) y Fuente Oficial INEI:
Al cruzar los 433 puntos entre la delimitación de terceros de GitHub y la capa oficial del INEI, se identificó que **5 puntos cambiaron de distrito**:

| FID | Nombre o C | EOMR | Coordenadas (Lat, Lon) | Distrito en GitHub | Distrito Oficial INEI | UBIGEO INEI | Dist. al Límite INEI |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | ---: |
| **151** | R-1 Victor Raúl Haya de la Torre | EOMR-Comas | (-11.973601, -77.055327) | COMAS | **INDEPENDENCIA** | `150112` | 2.48 m |
| **251** | P-828 | EOMR-Ate Vitarte | (-11.993059, -76.836077) | ATE | **CHACLACAYO** | `150107` | 105.97 m |
| **280** | P-458 | EOMR-Ate Vitarte | (-12.027510, -76.954434) | ATE | **EL AGUSTINO** | `150111` | 26.08 m |
| **283** | P-466 | EOMR-Ate Vitarte | (-12.022743, -76.944372) | ATE | **EL AGUSTINO** | `150111` | 40.33 m |
| **360** | S0059B | EOMR-Surquillo | (-12.128819, -77.009546) | MIRAFLORES | **SANTIAGO DE SURCO** | `150140` | 2.44 m |

### Puntos por Distrito bajo la Delimitación Oficial INEI (36 Distritos):
- **Ate:** 48 | **Carabayllo:** 36 | **Comas:** 36 | **San Juan de Lurigancho:** 34 | **Puente Piedra:** 33 | **Callao:** 27 | **Santiago de Surco:** 27 | **San Martín de Porres:** 21 | **Lurigancho (Chosica):** 17 | **La Molina:** 12 | **Villa El Salvador:** 12 | **San Miguel:** 11 | **Lima (Cercado):** 11 | **El Agustino:** 11 | **Bellavista:** 10 | **Santa Anita:** 10 | **San Isidro:** 8 | **San Borja:** 8 | **Los Olivos:** 7 | **Independencia:** 7 | **Chaclacayo:** 6 | **Miraflores:** 6 | **La Victoria:** 5 | **Chorrillos:** 5 | **Pueblo Libre:** 4 | **Cieneguilla:** 4 | **Surquillo:** 3 | **Lince:** 3 | **San Luis:** 3 | **San Juan de Miraflores:** 2 | **Barranco:** 1 | **Breña:** 1 | **La Punta:** 1 | **Ventanilla:** 1 | **Carmen de la Legua Reynoso:** 1 | **Villa María del Triunfo:** 1.

### Proximidad a Límites Distritales INEI:
- **Puntos a $< 20\text{ m}$ del límite oficial (13 puntos):** FID 151 (2.48 m), FID 360 (2.44 m), FID 361 (5.86 m), FID 389 (5.83 m), FID 388 (8.84 m), FID 359 (9.65 m), FID 358 (10.88 m), FID 143 (11.56 m), FID 160 (13.79 m), FID 152 (15.53 m), FID 108 (16.49 m), FID 99 (16.49 m), FID 174 (19.46 m).
- **Puntos entre 20 m y 50 m (23 puntos).**
- **Puntos interiores $\ge 50\text{ m}$ (397 puntos).**

### Distritos sin Puntos Fijos Provisionales:
Estos distritos no contienen puntos provisionales fijos dentro de sus límites según el dataset analizado. La estrategia de abastecimiento aplicable —uso de puntos en distritos vecinos, cisternas, puntos temporales u otras modalidades— requiere validación institucional:
`ANCON`, `JESUS MARIA`, `LA PERLA`, `LURIN`, `MAGDALENA DEL MAR`, `MI PERU`, `PACHACAMAC`, `PUCUSANA`, `PUNTA HERMOSA`, `PUNTA NEGRA`, `RIMAC`, `SAN BARTOLO`, `SANTA MARIA DEL MAR`, `SANTA ROSA`.

---

## 13. Rediseño del Identificador y Algoritmo de Reconciliación

### Distancias Mínimas entre Puntos Distintos en el Dataset:
- Par de puntos más cercano: **$10.91\text{ metros}$** (entre FID 118 [`P-487`] y FID 121 [`P-378`] en Comas).
- Segundo par más cercano: **$16.49\text{ metros}$** (entre FID 108 [`P-661`] y FID 99 [`R-1 Santo Domingo`] en Comas).
- Tercer par más cercano: **$20.65\text{ metros}$** (entre FID 358 [`S0068`] y FID 359 [`S0055`] en Surquillo).
- **Conclusión Técnica:** Un umbral automático ciego basado únicamente en distancia provocaría colisiones y fusiones erróneas de infraestructura.

### Algoritmo de Reconciliación Multi-Factor:
```text
Nueva fila recibida de SEDAPAL:
│
├── 1. Concordancia por Fingerprint Exacto:
│      ¿Coincide source_record_fingerprint con registro existente?
│      └── SÍ: Registro idéntico sin cambios.
│
├── 2. Coincidencia Fuerte por Código Oficial:
│      Condiciones acumulativas obligatorias:
│      a) official_code no es null
│      b) official_code no es valor genérico ("ATARJEA")
│      c) official_code es único en el dataset previo
│      d) official_code es único en el nuevo archivo
│      e) EOMR coincide
│      f) Distancia geográfica < 100 metros
│      └── SÍ: Misma infraestructura con atributos actualizados. Conservar water_point_id.
│
├── 3. Casos Ambigüos o con Códigos No Únicos (FID 24, "ATARJEA", "R-P1" a "R-P5"):
│      NO reconciliar por código. Ejecutar MULTI_FACTOR_MATCH:
│      - Concordancia de EOMR
│      - Concordancia de component_type_raw
│      - Similitud textual estricta de Ubicación normalizada
│      - Distancia física estricta < 10 metros
│      - Atributos técnicos complementarios (Otros / Capacidad)
│      └── Si existe 1 único candidato inequívoco: Reconciliar y conservar water_point_id.
│      └── Si existen 2 o más candidatos o ninguno: Clasificar como NEEDS_MANUAL_REVIEW.
│
└── 4. Alta de Nuevo Punto:
       Si no cumple con ninguna de las anteriores, generar nuevo water_point_id.
```

---

## 14. Separación entre Ciclo de Vida del Activo y Estado Dinámico

Se desacopló el ciclo de vida del dato maestro de la infraestructura respecto al estado dinámico de contingencia:

1. **Ciclo de Vida de la Infraestructura (`WaterPoint` — Dato Maestro):**
   - `lifecycle_status`:
     - `CURRENT`: Punto activo y vigente en el catálogo maestro oficial.
     - `MISSING_FROM_LATEST_SOURCE`: Punto que no figura en la última entrega recibida; pasa a estado de observación preventiva sin darse de baja automáticamente.
     - `RETIRED`: Punto formalmente retirado tras confirmación y regla institucional.
     - `PENDING_REVIEW`: Punto con ambigüedad o discrepancia en proceso de revisión manual.
   - `valid_from`: Fecha de incorporación oficial (e.g. `2026-08-19`).
   - `valid_to`: Fecha de baja definitiva (o `null` si está vigente).

2. **Estado Operativo Dinámico en Emergencia (`WaterPointStatus` — Dato Dinámico):**
   - `operational_status`: `UNKNOWN`, `OPERATIONAL`, `NO_WATER`, `INACCESSIBLE`, `SATURATED`.
   - `queue_level`: Nivel de congestión en tiempo real.
   - `estimated_wait_minutes`: Tiempo estimado de espera en cola.
   - `valid_until`: Vigencia temporal de la observación para descarte por obsolescencia.
