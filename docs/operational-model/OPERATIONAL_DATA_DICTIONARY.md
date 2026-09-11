# Diccionario de Datos del Modelo Operacional — AguaCION / SUNASS

**Documento:** Matriz Técnica de Atributos Operacionales
**Hito:** Hito 3A
**Fecha:** 11 de septiembre de 2026
**Estado:** ESPECIFICACIÓN TÉCNICA BASE (Revisión Correctiva de Rigor)

---

## 1. Introducción y Convenciones

La siguiente matriz documenta exhaustivamente los campos del dominio en **AguaCION / Agua Segura Perú**.
Cada atributo está categorizado según su carácter inmutable/estático o temporal/dinámico, su procedencia (*Source*), su sujeción a políticas de frescura (*Freshness*) y la necesidad de validación institucional por parte de SUNASS o SEDAPAL.

---

## 2. Matriz de Atributos del Modelo de Dominio

| Campo | Modelo | Tipo Dart | Nullable | Estático / Dinámico | Fuente Principal | Sujeto a Freshness | Validación Institucional Requerida | Notas Técnicas y Semánticas |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `waterPointId` | `WaterPoint` | `String` | No | Estático | AguaCION (Normalizado) | No | No | Hash sintético estable normalizado (e.g. `WP-SED-SUR-3B91385998-SAN ISIDRO`). |
| `sourceRecordFingerprint` | `WaterPoint` | `String?` | Sí | Estático | Ingestión / Pipeline | No | No | Huella hash de atributos fuente para detectar alteraciones en entregas oficiales. |
| `officialCode` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL / SUNASS | No | SÍ | Código patrimonial corporativo en GIS de SEDAPAL (actualmente nulo en el Excel). |
| `name` | `WaterPoint` | `String` | No | Estático | SEDAPAL | No | SÍ | Nombre de referencia oficial (e.g. `Ca. Los Cedros Cdra. 03 (Parque Dammert)`). |
| `componentTypeRaw` | `WaterPoint` | `String` | No | Estático | SEDAPAL | No | SÍ | Tipo de activo: `CÁMARA CON MANIFOLD`, `POZO`, `RESERVORIO`. |
| `infrastructureLocation` | `WaterPoint` | `GeoLocation` | No | Estático | SEDAPAL | No | SÍ | Coordenada física del equipo hidráulico (bomba, válvula, pozo). |
| `displayLocation` | `WaterPoint` | `GeoLocation` | No | Estático | Derivado | No | No | Ubicación utilizada estrictamente para posicionar el icono en el mapa visual. |
| `pedestrianAccessLocation` | `WaterPoint` | `GeoLocation?` | Sí | Estático | Auditoría / SEDAPAL | No | SÍ | Coordenada del portón peatonal verificado. Nula si no está verificada. **Cero coordenadas inventadas**. |
| `routingAccessLocation` | `WaterPoint` | `GeoLocation?` | Sí | Estático | Derivado | No | SÍ | Acceso peatonal para enrutamiento. Si es nulo, acceso permanece como no validado (`UNVERIFIED_ACCESS_LOCATION`). |
| `provisionalTechnicalRoutingTarget` | `WaterPoint` | `GeoLocation` | No | Estático | Derivado Técnico | No | No | Fallback provisional para el grafo del POC. Rotulado taxativamente: `PROVISIONAL_TECHNICAL_ROUTING_TARGET`. |
| `department` | `WaterPoint` | `String` | No | Estático | INEI / SEDAPAL | No | No | Departamento (`LIMA`). |
| `province` | `WaterPoint` | `String` | No | Estático | INEI / SEDAPAL | No | No | Provincia (`LIMA` o `CALLAO`). |
| `district` | `WaterPoint` | `String` | No | Estático | INEI / SEDAPAL | No | SÍ | Distrito. **Metadato geográfico descriptivo, NO hard filter**. |
| `districtUbigeo` | `WaterPoint` | `String?` | Sí | Estático | INEI | No | No | Código oficial de 6 dígitos del distrito (e.g. `150131`). |
| `eomr` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL | No | No | Equipo de Operación y Mantenimiento de Redes (e.g. `EOMR-SUR`). |
| `capacityRaw` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL | No | **SÍ (BLOQUEANTE)** | Magnitud numérica sin unidad (15.00, 2.00, etc.). Prohibido inventar unidades. |
| `situationRaw` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL | No | **SÍ (BLOQUEANTE)** | `Operativo`, `En implementación`, `En reparación`. |
| `stateRaw` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL | No | **SÍ (BLOQUEANTE)** | `Activo`, `En reserva`. (111 puntos figuran Operativo + En reserva). |
| `generatorRaw` | `WaterPoint` | `String?` | Sí | Estático | SEDAPAL | No | SÍ | `Sí`, `No`, `No corresponde`. Indica si cuenta con grupo electrógeno propio. |
| `lifecycleStatus` | `WaterPoint` | `LifecycleStatus` | No | Estático / Admin | Catastro / SUNASS | No | SÍ | `active`, `missingFromLatestSource`, `pendingReview`, `retired`. |
| `accessibilityInfo` | `WaterPoint` | `AccessibilityInfo?` | Sí | Estático / Físico | Relevamiento en Campo | No | SÍ | Rampa para silla de ruedas, escaleras, pendiente. Nulo si no se conoce. |
| `operationalStatus` | `WaterPointStatus` | `OperationalStatus` | No | **Dinámico** | Operador / COE / App | **SÍ** | **SÍ (BLOQUEANTE)** | `unknown`, `operational`, `limited`, `temporarilyUnavailable`, `closed`. |
| `waterAvailability` | `WaterPointStatus` | `WaterAvailability` | No | **Dinámico** | Operador / Sensor / App | **SÍ** | **SÍ (BLOQUEANTE)** | `unknown`, `available`, `low`, `temporarilyEmpty`, `unavailable`. |
| `queueLevel` | `WaterPointStatus` | `QueueLevel` | No | **Dinámico** | Reporte / Operador | **SÍ** | SÍ | `unknown`, `low`, `medium`, `high`, `saturated`. Ordinal, sin minutos ficticios. |
| `estimatedWaitMinutes` | `WaterPointStatus` | `int?` | Sí | **Dinámico** | Operador en Sitio | **SÍ** | SÍ | Minutos de espera medidos en terreno. Estrictamente nulo si no hay medición. |
| `accessStatus` | `WaterPointStatus` | `AccessStatus` | No | **Dinámico** | Operador / Incidente | **SÍ** | SÍ | `unknown`, `accessible`, `restricted`, `blocked`, `closed`. |
| `updatedAt` | `WaterPointStatus` | `DateTime` | No | **Dinámico** | Telemetría / Emisión | **SÍ** | No | Timestamp exacto de emisión de la observación. |
| `validUntil` | `WaterPointStatus` | `DateTime?` | Sí | **Dinámico** | Telemetría / Emisión | **SÍ** | SÍ | Expiración programada del turno o anuncio temporal. |
| `sourceType` | `WaterPointStatus` | `SourceType` | No | **Dinámico** | Procedencia | No | SÍ | `officialSunass`, `officialSedapal`, `coe`, `accreditedOperator`, `citizenReport`, etc. |
| `confidenceLevel` | `WaterPointStatus` | `ConfidenceLevel` | No | **Dinámico** | Motor de Confianza | No | SÍ | `unknown`, `low`, `medium`, `high`, `verified`. |
| `operationalDecision` | `SourceConflict` | `String` | No | **Dinámico** | Dominio de Conflicto | No | **SÍ (BLOQUEANTE)** | `PENDING_POLICY`. El software no arbitra quién tiene la verdad unilateralmente. |
| `minimumReports` | `CitizenCorroborationPolicy` | `int?` | Sí | Configuración | Parámetro de Agregación | No | SÍ | Nulo por defecto (`PENDING_INSTITUTIONAL_VALIDATION`). **Cero umbrales hardcodeados**. |
| `timeWindow` | `CitizenCorroborationPolicy` | `Duration?` | Sí | Configuración | Parámetro de Agregación | No | SÍ | Nulo por defecto (`PENDING_INSTITUTIONAL_VALIDATION`). **Cero umbrales hardcodeados**. |
| `freshDuration` | `FreshnessPolicy` | `Duration?` | Sí | Configuración | Política de Frescura | No | SÍ | Nulo por defecto (`POLICY_NOT_CONFIGURED`). **0 TTLs productivos hardcodeados**. |
| `agingDuration` | `FreshnessPolicy` | `Duration?` | Sí | Configuración | Política de Frescura | No | SÍ | Nulo por defecto (`POLICY_NOT_CONFIGURED`). **0 TTLs productivos hardcodeados**. |
| `staleDuration` | `FreshnessPolicy` | `Duration?` | Sí | Configuración | Política de Frescura | No | SÍ | Nulo por defecto (`POLICY_NOT_CONFIGURED`). **0 TTLs productivos hardcodeados**. |
| `incidentId` | `Incident` | `String` | No | **Dinámico** | Sistema / COE | No | No | Identificador unívoco del incidente vial. |
| `affectedGraphEdgeIds` | `Incident` | `List<int>` | No | **Dinámico** | Topología Vial | **SÍ** | SÍ | Aristas del grafo peatonal deshabilitadas para A*. |
| `reportId` | `CitizenReport` | `String` | No | **Dinámico** | Dispositivo Ciudadano | No | No | UUID del reporte ciudadano. |
| `deviceGeneratedId` | `CitizenReport` | `String` | No | **Dinámico** | Dispositivo Ciudadano | No | No | Token local para garantizar idempotencia en reintentos. |
| `syncStatus` | `CitizenReport` | `ReportSyncStatus` | No | **Dinámico** | Outbox | No | No | `pending`, `syncing`, `synced`, `failed`, `rejected`. |
| `outboxId` | `OutboxItem` | `String` | No | **Dinámico** | Cola SQLite Local | No | No | Identificador en cola persistente *Store & Forward*. |
| `eventId` | `OperationalEvent` | `String` | No | **Dinámico** | Audit Logger | No | No | Identificador inmutable de auditoría (append-only). |
| `digitalSignature` | `OperationalEvent` | `String?` | Sí | **Dinámico** | Criptografía | No | SÍ | `FUTURE_SECURITY_DESIGN, NOT_IMPLEMENTED, NOT_VALIDATED`. |
