# Architecture Decision Records (ADR) — Modelo Operacional de Puntos de Abastecimiento

**Proyecto:** AguaCION / Agua Segura Perú (SUNASS)
**Hito:** Hito 3A
**Fecha:** 11 de septiembre de 2026
**Estado:** APROBADO / BASE TÉCNICA (Revisión Correctiva de Rigor)

---

## Índice de ADRs

- [ADR-001: Separación entre WaterPoint Estático y WaterPointStatus Dinámico](#adr-001-separación-entre-waterpoint-estático-y-waterpointstatus-dinámico)
- [ADR-002: Persistencia Local en Dispositivo Móvil Mediante SQLite / Drift](#adr-002-persistencia-local-en-dispositivo-móvil-mediante-sqlite--drift)
- [ADR-003: Registro de Observaciones y Eventos Históricos vs. Almacenamiento Exclusivo del Último Estado](#adr-003-registro-de-observaciones-y-eventos-históricos-vs-almacenamiento-exclusivo-del-último-estado)
- [ADR-004: Adopción Estricta de UNKNOWN Explícito y Políticas de Frescura No Configuradas](#adr-004-adopción-estricta-de-unknown-explícito-y-políticas-de-frescura-no-configuradas)
- [ADR-005: Rechazo de Fórmulas Ponderadas Arbitrarias ("Magic Scores") en favor de Recomendación Explicable por Fases](#adr-005-rechazo-de-fórmulas-ponderadas-arbitrarias-magic-scores-en-favor-de-recomendación-explicable-por-fases)
- [ADR-006: Distrito como Metadato Geográfico y Prohibición de Hard Filter Distrital](#adr-006-distrito-como-metadato-geográfico-y-prohibición-de-hard-filter-distrital)
- [ADR-007: No Utilización de Blockchain para MVP y Estado de Auditoría](#adr-007-no-utilización-de-blockchain-para-mvp-y-estado-de-auditoría)

---

## ADR-001: Separación entre WaterPoint Estático y WaterPointStatus Dinámico

### Contexto
En las fases iniciales del proyecto (Hitos 1 y 2), el modelo representaba la infraestructura física de 433 puntos oficiales. Sin embargo, durante emergencias, las características físicas de un activo patrimonial son permanentes en escalas de años o décadas, mientras que su estado operacional (disponibilidad de agua, fila, averías) cambia continuamente.

### Decisión
Separar taxativamente el modelo en dos entidades desacopladas:
1. `WaterPoint`: Representa la infraestructura física patrimonial inmutable (`waterPointId`, coordenadas, tipo de activo, situación y estado del catálogo). No contiene atributos temporales.
2. `WaterPointStatus`: Representa una observación operacional temporal acotada (`updatedAt`, `validUntil`), con procedencia (`sourceType`), nivel de confianza (`confidenceLevel`) y estados operacionales.

### Consecuencias
- **Positivas:** El catálogo offline de 433 puntos no requiere ser mutado o reescrito cada vez que se recibe un reporte.
- **Negativas:** La UI debe combinar la infraestructura base con su último estado válido evaluado a tiempo de consulta.

---

## ADR-002: Persistencia Local en Dispositivo Móvil Mediante SQLite / Drift

### Contexto
Durante sismos de gran magnitud, la conectividad a Internet es nula o intermitente. La app debe almacenar localmente cientos de reportes ciudadanos en cola (*Store & Forward*), incidencias viales y metadatos. Soluciones basadas en clave-valor como `SharedPreferences` no ofrecen atomicidad transaccional ACID ni soporte de índices.

### Decisión
Adoptar como estándar arquitectónico de persistencia operacional local en el dispositivo móvil:
- Motor relacional embebido **SQLite**, complementado en Flutter mediante la librería tipada **Drift**.
- Se prohíbe taxativamente almacenar colas transaccionales de reportes o estados operacionales en `SharedPreferences`.

### Consecuencias
- **Positivas:** Integridad transaccional garantizada, prevención de corrupción ante cierre súbito de la app e indexación eficiente.
- **Negativas:** Dependencia de compilación nativa en Android e iOS.

---

## ADR-003: Registro de Observaciones y Eventos Históricos vs. Almacenamiento Exclusivo del Último Estado

### Contexto
En emergencias institucionales con SUNASS y SEDAPAL, surge el requerimiento de auditar por qué se emitió cierta recomendación y resolver disputas. Un modelo que sobrescribe destructivamente el estado anterior impide cualquier auditoría y anula la capacidad de detectar contradicciones.

### Decisión
Implementar un modelo append-only para observaciones y eventos:
1. Registrar instancias inmutables de `WaterPointObservation` y `OperationalEvent`.
2. Proyectar el `WaterPointStatus` vigente a partir del conjunto de observaciones válidas.
3. Almacenar los reportes ciudadanos en `citizen_reports` sin sobrescribir directamente el estado oficial sin corroboración.
4. Modelar contradicciones mediante `SourceConflict` con estado `CONFLICTING_INFORMATION` y decisión `PENDING_POLICY`.

### Consecuencias
- **Positivas:** Trazabilidad institucional absoluta y detección formal de conflictos entre fuentes.
- **Negativas:** Requiere purga periódica en el móvil para no saturar el almacenamiento tras períodos prolongados.

---

## ADR-004: Adopción Estricta de UNKNOWN Explícito y Políticas de Frescura No Configuradas

### Contexto
En emergencias, guiar a un ciudadano prometiendo agua disponible cuando no hay información en tiempo real pone en riesgo su seguridad. Asimismo, fijar ventanas de tiempo arbitrarias (como 1 hora o 15 minutos) como reglas productivas carece de sustento institucional.

### Decisión
1. Todos los enums y campos operacionales admiten obligatoriamente el estado `unknown` o valores nulos cuando la información no ha sido confirmada.
2. `FreshnessPolicy` rechaza TTLs productivos hardcodeados. Su postura por defecto es `POLICY_NOT_CONFIGURED` (`FreshnessState.policyNotConfigured`).
3. Cualquier umbral temporal utilizado en pruebas locales debe rotularse expresamente como `LOCAL_SIMULATION / DEMO_ONLY (EXAMPLE ONLY — NOT INSTITUTIONALLY VALIDATED)`.
4. El sistema prohíbe inventar unidades de medida para `capacityRaw` o asumir que `Situación = Operativo` en el catálogo estático equivale a agua fluyendo durante el sismo.

### Consecuencias
- **Positivas:** Veracidad informativa y protección contra desinformación en desastres.
- **Negativas:** La interfaz debe comunicar incertidumbre de manera clara al usuario.

---

## ADR-005: Rechazo de Fórmulas Ponderadas Arbitrarias ("Magic Scores") en favor de Recomendación Explicable por Fases

### Contexto
Fórmulas del tipo $\text{Score} = 0.40 \cdot \text{Distancia} + 0.30 \cdot \text{Cola} + 0.30 \cdot \text{Disponibilidad}$ son arbitrarias y matemáticamente opacas para la ciudadanía y los reguladores.

### Decisión
1. Rechazar formalmente cualquier fórmula de puntaje ponderado numérico.
2. Adoptar un pipeline explicable por fases deterministas:
   - Evaluación de filtros duros técnicos potenciales.
   - Evaluación de frescura y confianza.
   - Cálculo de distancias y tiempos reales de caminata por A*.
   - Presentación simultánea de hasta tres resultados: **RECOMENDADO**, **ALTERNATIVA**, **MÁS CERCANO**.
3. Eliminar taxativamente el término "Recomendado Seguro", empleando como máximo "Recomendado".
4. Cada sugerencia debe acompañarse de su justificación legible mediante `RecommendationReason`.

### Consecuencias
- **Positivas:** Transparencia total ante la ciudadanía y auditores de SUNASS.
- **Negativas:** Requiere árboles de decisión estructurados en lugar de una simple suma multiplicativa.

---

## ADR-006: Distrito como Metadato Geográfico y Prohibición de Hard Filter Distrital

### Contexto
En Lima y Callao existen 14 distritos con cero (0) puntos provisionales fijos en el catálogo oficial de 433 puntos. Si el sistema filtrara rígidamente por distrito, los ciudadanos de dichas demarcaciones quedarían desprovistos en el mapa.

### Decisión
```
DISTRICT_HARD_FILTER = NO
```
**Redacción Normativa de la Política:**
> *"El distrito no excluye automáticamente candidatos. Un punto de otro distrito puede ser evaluado si no existe una regla institucional de área de servicio."*

- El distrito actúa estrictamente como **metadato geográfico descriptivo**.
- No existe preferencia a favor ni en contra de cruzar fronteras distritales; la evaluación se rige por la red peatonal caminable.

### Consecuencias
- **Positivas:** Los ciudadanos de distritos sin puntos registrados pueden acceder al punto más cercano viable en un distrito contiguo.
- **Negativas:** Requiere coordinación institucional entre municipios para evitar quejas de saturación interdistrital.

---

## ADR-007: No Utilización de Blockchain para MVP y Estado de Auditoría

### Contexto
Se evaluó si una red distribuida (Blockchain / DLT) era requerida para garantizar la inmutabilidad de reportes y auditoría.

### Decisión
Documentar formalmente:
```
BLOCKCHAIN_REQUIRED_FOR_MVP = NO
DIGITAL_SIGNATURE_AUDIT_IMPLEMENTED = NO
```

**Justificación Técnica y Alcance:**
1. Blockchain no resuelve la ausencia de conectividad celular en un terremoto, no mejora el GPS, no optimiza el routing A* y acelera el agotamiento de la batería móvil.
2. Un registro append-only local (`OperationalEvent`) cubre plenamente el diseño conceptual de auditoría para el MVP.
3. Las firmas digitales asimétricas, el sellado de tiempo institucional y la infraestructura criptográfica de claves públicas corresponden a:
   ```
   FUTURE_SECURITY_DESIGN
   NOT_IMPLEMENTED
   NOT_VALIDATED
   ```
   No se presentan como capacidades actualmente operativas en la aplicación.

### Consecuencias
- **Positivas:** Simplicidad arquitectónica, ejecución nativa en milisegundos y cero sobrecarga de red o batería.
- **Negativas:** Ninguna relevante para el uso offline de emergencia ciudadana.
