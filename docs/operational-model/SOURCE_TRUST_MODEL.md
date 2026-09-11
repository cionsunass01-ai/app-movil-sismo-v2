# Modelo de Fuentes, Confianza y Seguridad Operacional

**Proyecto:** AguaCION / Agua Segura Perú (SUNASS)
**Hito:** Hito 3A
**Fecha:** 11 de septiembre de 2026
**Estado:** ESPECIFICACIÓN TÉCNICA BASE (Revisión Correctiva de Rigor)

---

## 1. Tipología de Fuentes ([`SourceType`](lib/domain/source/source_type.dart))

En situaciones de emergencia sísmica o corte masivo del suministro de agua, la información proviene de múltiples actores con diferentes grados de fiabilidad institucional y técnica.
El modelo distingue taxativamente los siguientes orígenes:

| Identificador | Denominación Institucional | Descripción | Tratamiento en UI |
| :--- | :--- | :--- | :--- |
| `officialSunass` | Oficial SUNASS | Verificación directa del regulador mediante sus brigadas de fiscalización o COE institucional. | Insignia institucional oficial con alta prioridad. |
| `officialSedapal` | Oficial SEDAPAL | Boletines, plataformas GIS corporativas o comunicados del prestador del servicio. | Insignia oficial de prestador. |
| `coe` | COE / INDECI | Centro de Operaciones de Emergencia Nacional o Sectorial. | Máxima prioridad para incidentes y alertas de peligro. |
| `accreditedOperator` | Operador Acreditado en Campo | Cuadrillas técnicas de campo, serenazgo municipal capacitado o brigadistas de Cruz Roja/ONGs. | Alta confianza; reporte técnico directo en sitio. |
| `citizenReport` | Reporte Ciudadano | Observaciones enviadas por ciudadanos a través de la aplicación móvil. | Requiere corroboración; jamás sobrescribe unilateralmente el estado oficial. |
| `systemInference` | Inferencia del Sistema | Extrapolación matemática, propagación espacial o lógica basada en histórico. | Claramente etiquetado como "Estimación algorítmica". |
| `localSimulation` | Simulación Local de Prueba | Datos sintéticos generados en memoria para validación técnica, pruebas unitarias o demos. | **ETIQUETADO OBLIGATORIO DE SIMULACIÓN**. Prohibido presentar como dato real. |

---

## 2. Niveles de Confianza ([`ConfidenceLevel`](lib/domain/source/confidence_level.dart))

En lugar de calcular porcentajes ficticios (e.g. "87% de certeza"), el sistema utiliza una categorización ordinal explicable:

1. **`unknown` (No determinado):** Estado por defecto cuando no existe informe reciente ni evaluación de procedencia.
2. **`low` (Baja):** Un único reporte ciudadano aislado (`singleCitizenReport`).
3. **`medium` (Media):** Múltiples reportes ciudadanos concordantes (`multipleConcordantCitizenReports`) o informe secundario preliminar.
4. **`high` (Alta):** Telemetría directa de operador de campo acreditado o comunicado verificado de SEDAPAL / SUNASS.
5. **`verified` (Verificado en Terreno):** Inspección presencial realizada por un fiscalizador acreditado de SUNASS.

---

## 3. Agregación Ciudadana y Umbrales ([`CitizenCorroborationPolicy`](lib/domain/source/citizen_corroboration_policy.dart))

> [!IMPORTANT]
> **CERO UMBRALES ARBITRARIOS HARDCODEADOS:**
> Reglas como *"≥ 5 reportes en < 45 min"* **NO tienen validación institucional**.
> El modelo de dominio define [`CitizenCorroborationPolicy`](lib/domain/source/citizen_corroboration_policy.dart) con parámetros configurables:
> - `minimumReports`: `int?` (`null` por defecto / `PENDING_INSTITUTIONAL_VALIDATION`).
> - `timeWindow`: `Duration?` (`null` por defecto / `PENDING_INSTITUTIONAL_VALIDATION`).
>
> Cualquier combinación numérica (como 5 reportes en 45 minutos) se reserva estrictamente para demostraciones locales sintéticas rotuladas como `LOCAL_SIMULATION_DEMO_ONLY (EXAMPLE ONLY — NOT INSTITUTIONALLY VALIDATED)`.

---

## 4. Detección y Representación de Conflictos de Fuentes ([`SourceConflict`](lib/domain/water/observation_model.dart#L108))

El sistema modela formalmente situaciones donde coexisten reportes contradictorios:

- **Estructura:** [`SourceConflict`](lib/domain/water/observation_model.dart#L108) vincula la observación oficial y las observaciones ciudadanas u operacionales divergentes.
- **Estado Técnico:** `status = CONFLICTING_INFORMATION`.
- **Decisión Operacional:** `operationalDecision = PENDING_POLICY`.
- **Prohibición de Resolución Automática Arbitraria:**
  - El software **NO resuelve unilateralmente** quién tiene la verdad.
  - Se prohíbe implementar reglas automáticas tales como: *"Si 20 ciudadanos contradicen a SEDAPAL, retirar automáticamente el punto"*.
  - En Hito 3A, el sistema solo **representa el conflicto** de forma neutral y auditable, dejando la política de desempate en estado `PENDING_POLICY` para validación formal con SUNASS y SEDAPAL (Pregunta N° 18).
- **Terminología de Recomendación:**
  - Se elimina taxativamente la expresión *"Recomendado Seguro"*.
  - Se utiliza como máximo el término **"Recomendado"**, reconociendo que AguaCION no puede garantizar la seguridad física en un escenario de desastre.

---

## 5. Modelo de Privacidad Ciudadana

- **Ubicación Local por Defecto:** La posición GPS del usuario se procesa al 100% en la memoria volátil del dispositivo para el enrutamiento peatonal. No se transmite a ningún servidor de rastreo.
- **Reportes con Acción Explícita:** La coordenada del ciudadano solo se incluye si este decide enviar voluntariamente un reporte ([`CitizenReport`](lib/domain/reporting/citizen_report.dart)).
- **Minimización Espacial:** El sistema prevé truncar la precisión de coordenadas a ~100 m o usar geohashes distritales en fases productivas.

---

## 6. Auditoría y Perfiles de Seguridad

- **Auditoría Append-Only Diseñada:** Modela eventos operacionales mediante [`OperationalEvent`](lib/domain/audit/operational_event.dart).
- **Estado de Criptografía y Firmas:**
  - `DIGITAL_SIGNATURE_AUDIT_IMPLEMENTED = NO`
  - Clasificación: `FUTURE_SECURITY_DESIGN, NOT_IMPLEMENTED, NOT_VALIDATED`.
  - En Hito 3A no existen firmas digitales activas ni sellado de tiempo criptográfico implementado; son especificaciones conceptuales para fases posteriores.
