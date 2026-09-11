# Diccionario de Datos — AguaCION / Agua Segura Perú

**Entidad Principal:** `WaterPoint` (Punto Fijo Provisional de Abastecimiento de Emergencia)
**Versión del Diccionario:** 2.0.0 (Fuente Territorial Oficial INEI Integrada)
**Fecha:** 10 de septiembre de 2026
**Ámbito:** Lima Metropolitana y Callao (SEDAPAL / SUNASS / INEI)

---

## 1. Convenciones y Clasificación de Origen

- **OFICIAL_SEDAPAL:** Campo provisto directamente en el consolidado de SEDAPAL (`Abastecimiento_Lima_metro.xlsx`).
- **OFICIAL_INEI:** Código o atributo extraído directamente de la capa oficial **Distrital (Actualizado al 2023)** del Portal IDE del INEI.
- **NORMALIZADO_SINTACTICO:** Campo derivado de un campo oficial tras limpieza tipográfica, homologación de mayúsculas y asignación a catálogo (*enum* neutral) sin inferir semántica no comprobada.
- **CALCULADO_GIS:** Campo obtenido mediante geoprocesamiento (*Point-in-Polygon*, cálculo de distancia perimetral).
- **TECNICO_INTERNO:** Identificador sintético o metadato de control del sistema AguaCION.
- **PENDIENTE_INSTITUCIONAL:** Atributo cuya semántica, unidad o validez requiere confirmación formal de SEDAPAL o SUNASS.

---

## 2. Especificación Campo por Campo

### 2.1 Identificadores y Control de Ciclo de Vida

#### `water_point_id`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Identificador canónico único y permanente de la infraestructura en AguaCION. No cambia aunque SEDAPAL altere la redacción o re-mida coordenadas con GPS.
- **Tipo de Dato:** `String` (formato `WP-SED-{EOMR}-{HASH10}`)
- **Ejemplo:** `"WP-SED-SJL-B0C1F8B924"`
- **Obligatoriedad:** OBLIGATORIO (Clave Primaria interna)
- **Estado de Validación:** VALIDADO_TECNICAMENTE (433 únicos)

#### `lifecycle_status`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Estado de vigencia del activo en el catálogo maestro de AguaCION.
- **Tipo de Dato:** `String` (Enum)
- **Valores Permitidos:**
  - `CURRENT`: Activo oficial vigente en el catálogo.
  - `MISSING_FROM_LATEST_SOURCE`: Ausente en la última entrega; en observación preventiva sin darse de baja.
  - `RETIRED`: Retirado formalmente tras confirmación institucional.
  - `PENDING_REVIEW`: En proceso de revisión manual por discrepancia.
- **Valor Inicial:** `"CURRENT"`
- **Obligatoriedad:** OBLIGATORIO

#### `valid_from`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Fecha desde la cual el punto está registrado y vigente en el catálogo oficial.
- **Tipo de Dato:** `String` (ISO 8601 Date: `"2026-08-19"`)
- **Obligatoriedad:** OBLIGATORIO

#### `valid_to`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Fecha de retiro formal del catálogo (o `null` si permanece vigente).
- **Tipo de Dato:** `String?` (anulable)
- **Valor Inicial:** `null`

#### `source_record_fingerprint`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Hash SHA-256 de los 11 campos crudos de la fila entregada por SEDAPAL. Permite detectar instantáneamente alteraciones entre versiones.
- **Tipo de Dato:** `String` (Hexadecimal SHA-256, 64 caracteres)
- **Obligatoriedad:** OBLIGATORIO

#### `source_fid`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Identificador de fila (*Feature ID*) de la exportación GIS original (0 a 432).
- **Tipo de Dato:** `Integer`
- **Obligatoriedad:** OBLIGATORIO (Trazabilidad de origen)

#### `official_code`
- **Origen:** OFICIAL_SEDAPAL / NORMALIZADO
- **Descripción:** Código o denominación institucional consignada en el campo `Nombre o C`.
- **Tipo de Dato:** `String?` (anulable)
- **Ejemplo:** `"P.109"`, `"CR-230"`, `null`
- **Obligatoriedad:** OPCIONAL (Presenta 1 nulo en FID 24 y múltiples duplicados como "ATARJEA" en VES).

---

### 2.2 Jurisdicción y Delimitación Territorial Oficial INEI

#### `eomr`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Equipo de Operación y Mantenimiento de Redes de SEDAPAL responsable del punto.
- **Tipo de Dato:** `String`
- **Obligatoriedad:** OBLIGATORIO

#### `eomr_code`
- **Origen:** NORMALIZADO_SINTACTICO
- **Descripción:** Código mnemotécnico corto (`SJL`, `CAL`, `COM`, `ATE`, `SUR`, `BRE`, `VES`).
- **Tipo de Dato:** `String`
- **Obligatoriedad:** OBLIGATORIO

#### `location_description`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Dirección física o referencia consignada en la columna `Ubicación`.
- **Tipo de Dato:** `String`
- **Obligatoriedad:** OBLIGATORIO

#### `department`
- **Origen:** OFICIAL_INEI (`NOMBDEP`)
- **Descripción:** Nombre del departamento político según la capa distrital oficial del INEI.
- **Tipo de Dato:** `String` (`"LIMA"`, `"CALLAO"`)
- **Obligatoriedad:** OBLIGATORIO

#### `department_code`
- **Origen:** OFICIAL_INEI (`CCDD`)
- **Descripción:** Código oficial de departamento del INEI (`"15"` para Lima, `"07"` para Callao).
- **Tipo de Dato:** `String` (2 dígitos)
- **Obligatoriedad:** OBLIGATORIO
- **Estado de Validación:** VALIDADO_OFICIAL_INEI (100% de cobertura)

#### `province`
- **Origen:** OFICIAL_INEI (`NOMBPROV`)
- **Descripción:** Nombre de la provincia según la capa oficial del INEI.
- **Tipo de Dato:** `String` (`"LIMA"`, `"CALLAO"`)
- **Obligatoriedad:** OBLIGATORIO

#### `province_code`
- **Origen:** OFICIAL_INEI (`CCPP`)
- **Descripción:** Código oficial de provincia del INEI (`"01"` para Lima Metropolitana y Callao).
- **Tipo de Dato:** `String` (2 dígitos)
- **Obligatoriedad:** OBLIGATORIO
- **Estado de Validación:** VALIDADO_OFICIAL_INEI (100% de cobertura)

#### `district`
- **Origen:** OFICIAL_INEI (`NOMBDIST`)
- **Descripción:** Nombre oficial del distrito político según la capa distrital del INEI.
- **Tipo de Dato:** `String` (36 distritos con puntos fijos)
- **Ejemplo:** `"ATE"`, `"COMAS"`, `"INDEPENDENCIA"`, `"SANTIAGO DE SURCO"`
- **Obligatoriedad:** OBLIGATORIO
- **Estado de Validación:** VALIDADO_OFICIAL_INEI

#### `district_code`
- **Origen:** OFICIAL_INEI (`CCDI`)
- **Descripción:** Código oficial de distrito del INEI (2 dígitos).
- **Tipo de Dato:** `String` (2 dígitos)
- **Ejemplo:** `"03"` (Ate), `"10"` (Comas), `"12"` (Independencia)
- **Obligatoriedad:** OBLIGATORIO
- **Estado de Validación:** VALIDADO_OFICIAL_INEI

#### `district_ubigeo`
- **Origen:** OFICIAL_INEI (`UBIGEO`)
- **Descripción:** Código UBIGEO oficial de 6 dígitos del INEI (`CCDD` + `CCPP` + `CCDI`).
- **Tipo de Dato:** `String` (6 dígitos)
- **Ejemplo:** `"150103"` (Ate), `"150110"` (Comas), `"070101"` (Callao)
- **Obligatoriedad:** OBLIGATORIO
- **Estado de Validación:** VALIDADO_OFICIAL_INEI (433/433 asignados, 100% de cobertura)

#### `district_assignment_method`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Método geométrico utilizado.
- **Tipo de Dato:** `String`
- **Valor:** `"POINT_IN_POLYGON_INEI_2023"`
- **Obligatoriedad:** OBLIGATORIO

#### `distance_to_district_boundary_m`
- **Origen:** CALCULADO_GIS
- **Descripción:** Distancia perpendicular mínima en metros desde el punto de abastecimiento hasta el perímetro/límite distrital oficial del INEI.
- **Tipo de Dato:** `Float`
- **Ejemplo:** `2.44`, `2.48`, `872.99`
- **Obligatoriedad:** OBLIGATORIO

#### `boundary_proximity_flag`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Clasificación de proximidad al límite INEI para control de calidad.
- **Valores:**
  - `CRITICAL_BOUNDARY_PROXIMITY (<20m)` (13 puntos)
  - `NEAR_BOUNDARY (<50m)` (23 puntos)
  - `INTERIOR (>=50m)` (397 puntos)
- **Obligatoriedad:** OBLIGATORIO

---

### 2.3 Coordenadas y Geometría

#### `latitude`
- **Origen:** OFICIAL_SEDAPAL (`POINT_Y`)
- **Descripción:** Latitud geográfica WGS 84 (grados decimales).
- **Tipo de Dato:** `Float` (6 decimales)
- **Rango:** `[-12.235877, -11.818060]`
- **Obligatoriedad:** OBLIGATORIO

#### `longitude`
- **Origen:** OFICIAL_SEDAPAL (`POINT_X`)
- **Descripción:** Longitud geográfica WGS 84 (grados decimales).
- **Tipo de Dato:** `Float` (6 decimales)
- **Rango:** `[-77.160908, -76.772472]`
- **Obligatoriedad:** OBLIGATORIO

#### `utm_easting`
- **Origen:** OFICIAL_SEDAPAL (`UTM_E`)
- **Descripción:** Coordenada UTM Este en metros (WGS 84 / UTM Zona 18S).
- **Tipo de Dato:** `Float` (2 decimales)
- **Obligatoriedad:** OBLIGATORIO

#### `utm_northing`
- **Origen:** OFICIAL_SEDAPAL (`UTM_N`)
- **Descripción:** Coordenada UTM Norte en metros (WGS 84 / UTM Zona 18S).
- **Tipo de Dato:** `Float` (2 decimales)
- **Obligatoriedad:** OBLIGATORIO

#### `utm_discrepancy_meters`
- **Origen:** CALCULADO_GIS
- **Descripción:** Distancia entre coordenadas geográficas y proyectadas inversas (máx: 0.0745 m).
- **Tipo de Dato:** `Float`
- **Obligatoriedad:** OBLIGATORIO

---

### 2.4 Componente y Capacidad

#### `component_type_raw`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Texto original registrado en `Tipo de co`.
- **Tipo de Dato:** `String`
- **Valores:** `"Hidrante"`, `"Pozo"`, `"Cámara de rebombeo"`, `"GRIFO AMARILLO"`, `"Sector"`, `"Surtidor"`, `"Cámara de bombeo"`, `"Cámara SCADA"`, `"Cámara de derivación"`, `"Reservorio"`.
- **Obligatoriedad:** OBLIGATORIO

#### `component_type_normalized`
- **Origen:** NORMALIZADO_SINTACTICO
- **Descripción:** Representación sintáctica neutral en mayúsculas sin interpretaciones añadidas (`HIDRANTE`, `GRIFO_AMARILLO`, `POZO`, `CAMARA_REBOMBEO`, `CAMARA_BOMBEO`, `CAMARA_DERIVACION`, `CAMARA_SCADA`, `RESERVORIO`, `SECTOR`, `SURTIDOR`).
- **Tipo de Dato:** `String`
- **Obligatoriedad:** OBLIGATORIO

#### `capacity`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Magnitud numérica consignada en `Capacidad`.
- **Tipo de Dato:** `Float`
- **Valores:** `15.0`, `2.0`, `8.6`, `15.55`, `62.22`, `26.0`
- **Obligatoriedad:** OBLIGATORIO

#### `capacity_unit`
- **Origen:** PENDIENTE_INSTITUCIONAL
- **Descripción:** Unidad física de la magnitud expresada en `capacity`.
- **Tipo de Dato:** `String`
- **Valor Forzado:** `"UNKNOWN"`
- **Obligatoriedad:** OBLIGATORIO

---

### 2.5 Estados Operativos y Grupo Electrógeno

#### `situation_raw`
- **Origen:** OFICIAL_SEDAPAL
- **Valores:** `"Operativo"`, `"Reserva"`, `"En implementación"`, `"En reparación"`
- **Obligatoriedad:** OBLIGATORIO

#### `situation_normalized`
- **Origen:** NORMALIZADO_SINTACTICO
- **Valores:** `OPERATIVO`, `RESERVA`, `EN_IMPLEMENTACION`, `EN_REPARACION`
- **Obligatoriedad:** OBLIGATORIO

#### `status_raw`
- **Origen:** OFICIAL_SEDAPAL
- **Valores:** `"Activo"`, `"En reserva"`
- **Obligatoriedad:** OBLIGATORIO

#### `status_normalized`
- **Origen:** NORMALIZADO_SINTACTICO
- **Valores:** `ACTIVO`, `EN_RESERVA`
- **Obligatoriedad:** OBLIGATORIO

#### `situation_status_semantics`
- **Origen:** TECNICO_INTERNO
- **Valor:** `"PENDING_INSTITUTIONAL_DEFINITION"`
- **Observaciones:** No se deduce `available_to_citizen` de estos campos.

#### `generator_status_raw`
- **Origen:** OFICIAL_SEDAPAL
- **Valores:** `"No"`, `"No corresponde"`, `"NO"`, `"Sí"`
- **Obligatoriedad:** OBLIGATORIO

#### `generator_status_normalized`
- **Origen:** NORMALIZADO_SINTACTICO
- **Valores:** `YES`, `NO`, `NOT_APPLICABLE`
- **Obligatoriedad:** OBLIGATORIO

#### `other`
- **Origen:** OFICIAL_SEDAPAL
- **Descripción:** Texto libre de la columna `Otros`.
- **Tipo de Dato:** `String`
- **Obligatoriedad:** OBLIGATORIO

---

### 2.6 Metadatos de Fuentes Oficiales

#### `territorial_source_authority`
- **Origen:** TECNICO_INTERNO
- **Valor:** `"Instituto Nacional de Estadística e Informática (INEI)"`

#### `territorial_source_dataset`
- **Origen:** TECNICO_INTERNO
- **Valor:** `"Distrital (Actualizado al 2023) / DISTRITO.gpkg"`

#### `source_name`
- **Origen:** TECNICO_INTERNO
- **Valor:** `"SEDAPAL - Informe N° 052-2026-EOMR-SJL / Carta N° 1089-2026-GG"`

#### `source_version`
- **Origen:** TECNICO_INTERNO
- **Valor:** `"2026-08-19"`

#### `imported_at`
- **Origen:** TECNICO_INTERNO
- **Descripción:** Marca temporal UTC de ingesta.
