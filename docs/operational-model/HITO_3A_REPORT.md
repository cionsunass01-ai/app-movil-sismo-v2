# Informe de Cierre de Hito 3A — Modelo Operacional de Puntos de Abastecimiento

**Proyecto:** Agua Segura Perú / AguaCION
**Entidad Reguladora:** SUNASS
**Fecha:** 11 de septiembre de 2026
**Estado:** REVISIÓN CORRECTIVA DE RIGOR COMPLETADA

---

## 1. Resumen Ejecutivo

El **Hito 3A** ha culminado la definición, diseño e implementación del **Modelo Operacional de Puntos de Abastecimiento** para la aplicación móvil AguaCION, incorporando todas las correcciones de rigor técnico e institucional:

- **Desacoplamiento Estático vs. Dinámico:** [`WaterPoint`](lib/domain/water/water_point.dart) (infraestructura patrimonial) versus [`WaterPointStatus`](lib/domain/water/water_point_status.dart) (observaciones temporales de emergencia).
- **Acceso Peatonal No Inventado:** Separación de `displayLocation` (mapa) de `routingAccessLocation` (portón validado). El fallback del POC en grafo se etiqueta formalmente como `PROVISIONAL_TECHNICAL_ROUTING_TARGET`.
- **Cero TTLs Productivos Hardcodeados:** Postura productiva por defecto `POLICY_NOT_CONFIGURED` ([`FreshnessState.policyNotConfigured`](lib/domain/source/freshness.dart#L19)).
- **Cero Umbrales Ciudadanos Arbitrarios:** [`CitizenCorroborationPolicy`](lib/domain/source/citizen_corroboration_policy.dart) configurable con parámetros en `PENDING_INSTITUTIONAL_VALIDATION`.
- **Resolución Neutral de Conflictos:** [`SourceConflict`](lib/domain/water/observation_model.dart#L108) representa `CONFLICTING_INFORMATION` con `operationalDecision = PENDING_POLICY` sin resoluciones automáticas arbitrarias.
- **Término Prudente:** Eliminación de "Recomendado Seguro"; uso exclusivo de "Recomendado".
- **Auditoría sin Pretensiones:** `BLOCKCHAIN_REQUIRED_FOR_MVP = NO` y `DIGITAL_SIGNATURE_AUDIT_IMPLEMENTED = NO` (firmas y sellado: `FUTURE_SECURITY_DESIGN, NOT_IMPLEMENTED, NOT_VALIDATED`).
- **Política Distrital Exacta:** `DISTRICT_HARD_FILTER = NO`. *"El distrito no excluye automáticamente candidatos. Un punto de otro distrito puede ser evaluado si no existe una regla institucional de área de servicio."* Sin preferencia artificial a favor ni en contra de cruzar distritos.

---

## 2. Verificación de Criterios de Aceptación (22/22)

| N° | Criterio de Aceptación del Hito 3A | Estado | Evidencia / Implementación |
| :---: | :--- | :---: | :--- |
| 1 | `WaterPoint` separado de `WaterPointStatus`. | **CUMPLIDO** | `WaterPoint` contiene infraestructura física estática; `WaterPointStatus` contiene observaciones temporales dinámicas. |
| 2 | `displayLocation` y `routingAccessLocation` separados. | **CUMPLIDO** | `routingAccessLocation` es nulo si no está validado. Fallback técnico provisional rotulado `PROVISIONAL_TECHNICAL_ROUTING_TARGET`. Cero coordenadas inventadas. |
| 3 | `lifecycleStatus` y `operationalStatus` separados. | **CUMPLIDO** | `LifecycleStatus` (activo/retirado) no se confunde con `OperationalStatus` (operativo/cerrado temporal). |
| 4 | `UNKNOWN` modelado explícitamente en todos los enums. | **CUMPLIDO** | Soportado en `OperationalStatus`, `WaterAvailability`, `QueueLevel`, `AccessStatus`, `ConfidenceLevel`. |
| 5 | Disponibilidad de agua (`WaterAvailability`) modelada. | **CUMPLIDO** | Enums `available`, `low`, `temporarilyEmpty`, `unavailable`, `unknown`. Sin invención de caudales. |
| 6 | Nivel de cola y saturación (`QueueLevel`) modelado. | **CUMPLIDO** | Escala ordinal `low`, `medium`, `high`, `saturated`. `estimatedWaitMinutes` nullable. |
| 7 | Frescura (`FreshnessState` y `FreshnessPolicy`) modelada. | **CUMPLIDO** | 0 TTLs productivos hardcodeados. Postura por defecto `POLICY_NOT_CONFIGURED`. Demos marcadas `LOCAL_SIMULATION_DEMO_ONLY`. |
| 8 | Procedencia de datos (`SourceType`) modelada. | **CUMPLIDO** | Soportados: `officialSunass`, `officialSedapal`, `coe`, `accreditedOperator`, `citizenReport`, `systemInference`, `localSimulation`. |
| 9 | Nivel de confianza y agregación ciudadana modelados. | **CUMPLIDO** | 0 umbrales ciudadanos arbitrarios hardcodeados (`CitizenCorroborationPolicy` con `minimumReports` y `timeWindow` en `PENDING_INSTITUTIONAL_VALIDATION`). |
| 10 | Incidencias viales y de acceso (`Incident`) modeladas. | **CUMPLIDO** | Relaciona incidentes con puntos afectados y aristas del grafo peatonal (`affectedGraphEdgeIds`). |
| 11 | `CitizenReport` separado del estado oficial. | **CUMPLIDO** | Los reportes ciudadanos no mutan unilateralmente `WaterPointStatus`. Se almacenan como observaciones independientes. |
| 12 | Cola fuera de línea (*Outbox*) diseñada. | **CUMPLIDO** | `OutboxItem` con `deviceGeneratedId` idempotente, conteo de reintentos y estado *dead-letter*. |
| 13 | Metadatos de versión (`DatasetMetadata`) diseñados. | **CUMPLIDO** | Registro de versión, fecha de corte, fecha de instalación y hash SHA-256. |
| 14 | Distrito proscrito como *Hard Filter*. | **CUMPLIDO** | `DISTRICT_HARD_FILTER = NO`. Redacción neutral rigurosa aprobada. |
| 15 | Prohibición de puntajes ponderados mágicos (*Magic Scores*). | **CUMPLIDO** | Se rechazan fórmulas `0.4*dist + 0.3*cola`. Se adopta pipeline explicable por fases (ADR-005) sin el término "Recomendado Seguro". |
| 16 | Representación formal de "Sin recomendación disponible". | **CUMPLIDO** | `RecommendationResult.noRecommendation()` maneja puntos cerrados o inaccesibles sin inventar rutas. |
| 17 | Representación de conflicto entre fuentes neutral. | **CUMPLIDO** | `SourceConflict` modela `CONFLICTING_INFORMATION` con decisión `PENDING_POLICY` sin resolución automática unilateral. |
| 18 | `LOCAL_SIMULATION` claramente diferenciable. | **CUMPLIDO** | Flag `isSimulation` y aislamiento estricto en UI y registros de auditoría. |
| 19 | Preguntas institucionales actualizadas y clasificadas. | **CUMPLIDO** | Cuestionario institucional ampliado a 22 preguntas con clasificación de criticidad. |
| 20 | Architecture Decision Records (ADRs) documentados. | **CUMPLIDO** | 7 ADRs formalizados en `docs/operational-model/ADR_OPERATIONAL_MODEL.md`. |
| 21 | Batería completa de pruebas unitarias exitosa. | **CUMPLIDO** | `flutter test` = 32 tests superados (15 de Hito 2 + 17 de Hito 3A). Cobertura real medida: 28.07% global, 23.46% en `lib/domain/`. |
| 22 | Análisis estático sin incidencias. | **CUMPLIDO** | `flutter analyze` = 0 issues found. |

---

## 3. Delimitación Estricta del Alcance

Durante la ejecución del Hito 3A se respetaron todas las restricciones fijadas por SUNASS:
1. **NO se implementó backend:** No se escribieron endpoints ni llamadas HTTP productivas.
2. **NO se conectaron bases de datos remotas:** Cero integración con Firebase, Supabase o servidores en la nube.
3. **NO se alteraron los componentes del Hito 2D:** El grafo peatonal CSR (`lima_callao_pedestrian.csr`), los tiles vectoriales PMTiles (`lima_callao_osm.pmtiles`), el motor A*, el umbral conservador de snapping a 50 m y el atlas de glifos offline se mantuvieron intactos.
4. **NO se utilizó blockchain:** `BLOCKCHAIN_REQUIRED_FOR_MVP = NO` y `DIGITAL_SIGNATURE_AUDIT_IMPLEMENTED = NO`.
5. **NO se realizaron commits ni push en git:** Se preservó el árbol de trabajo local según las instrucciones.
