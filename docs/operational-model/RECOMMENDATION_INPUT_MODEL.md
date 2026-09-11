# Modelo de Entrada y Criterios de Recomendación

**Proyecto:** AguaCION / Agua Segura Perú (SUNASS)
**Hito:** Hito 3A
**Fecha:** 11 de septiembre de 2026
**Estado:** ESPECIFICACIÓN TÉCNICA BASE (Revisión Correctiva de Rigor)

---

## 1. Cambio Fundamental de Paradigma

En el Hito 2, el POC offline respondía a una pregunta puramente geométrica y de conectividad topológica:
> *¿Cuál punto oficial tiene la menor distancia o tiempo de ruta peatonal sobre el grafo disponible?*

Para una aplicación institucional en emergencias reales, esta pregunta es insuficiente y potencialmente engañosa: el punto más cercano podría estar cerrado con candado, sin agua o con vías bloqueadas.
El Hito 3 redefine el objetivo hacia:
> *De los puntos físicamente alcanzables, ¿cuál debería recomendar AguaCION según la información operacional disponible, frescura, confianza y transitabilidad?*

---

## 2. Acceso Peatonal vs. Infraestructura Hidráulica

El modelo operacional prohíbe taxativamente asumir que la coordenada patrimonial de un activo hidráulico es un acceso peatonal ciudadano validado:

- **Ubicación para Visualización (`displayLocation`):** Utiliza [`infrastructureLocation`](lib/domain/water/water_point.dart#L36) para posicionar el icono del pozo, reservorio o cámara en el mapa base.
- **Acceso Peatonal de Enrutamiento (`routingAccessLocation`):**
  - Si [`pedestrianAccessLocation`](lib/domain/water/water_point.dart#L40) está validado en terreno, se utiliza como destino de navegación peatonal.
  - Si es nulo, el acceso permanece clasificado explícitamente como **`UNVERIFIED_ACCESS_LOCATION`**.
- **Objetivo Técnico Provisional (`provisionalTechnicalRoutingTarget`):**
  - El motor POC técnico actual puede enrutar provisionalmente hacia la coordenada disponible para permitir pruebas de grafo, pero dicho destino se rotula formalmente como:
    ```
    PROVISIONAL_TECHNICAL_ROUTING_TARGET
    ```
  - **Cero Coordenadas Inventadas:** Bajo ninguna circunstancia el software extrapola o inventa coordenadas de portones sin validación institucional.

---

## 3. Clasificación de Filtros Duros Potenciales (Potential Hard Filters)

Ninguna regla institucional ambigua se activa como filtro productivo definitivo en Hito 3A. Cada filtro potencial se clasifica formalmente según su estado de validación:

| Filtro Duro Potencial | Clasificación de Política | Descripción Técnica / Dependencia |
| :--- | :--- | :--- |
| **Aislamiento en Grafo Peatonal** | `CONFIRMED_TECHNICAL` | El punto excede el umbral técnico de snapping ($50\text{ m}$) o no existe camino transitable en el grafo CSR. Regla puramente algorítmica. |
| **Infraestructura Retirada** | `PENDING_INSTITUTIONAL_VALIDATION` | `lifecycleStatus == retired`. Solo aplicable si SUNASS/SEDAPAL certifican formalmente la baja del activo. |
| **Cierre Operacional Confirmado** | `PENDING_INSTITUTIONAL_VALIDATION` | `operationalStatus == closed`. Requiere protocolo institucional sobre qué autoridad tiene la potestad de decretar el cierre. |
| **Agotamiento de Agua Confirmado** | `PENDING_INSTITUTIONAL_VALIDATION` | `waterAvailability == unavailable`. Requiere validación de sensores o telemetría autorizada. |
| **Bloqueo Vial por Incidente** | `PENDING_INSTITUTIONAL_VALIDATION` | Aristas viales bloqueadas por derrumbe o anegamiento. Requiere canal oficial de reporte vial. |
| **Área de Servicio Territorial** | `PENDING_INSTITUTIONAL_VALIDATION` | Exclusión por pertenecer a otra zona (`serviceAreaId`). Inactivo por defecto; requiere norma expresa de zonificación de emergencia. |
| **Exclusión por Conflicto de Fuentes** | `PENDING_INSTITUTIONAL_VALIDATION` | Retiro de candidatos con reportes contradictorios. Inactivo; requiere regla de desempate institucional. |
| **Barrera de Accesibilidad Motriz** | `FUTURE` | Exclusión por presencia de gradas o pendientes para usuarios en silla de ruedas. |

---

## 4. Criterios de Clasificación (Ranking Criteria)

A los candidatos evaluados se les analizan atributos descriptivos:
- Distancia de ruta caminable por grafo (`routeDistanceMeters`).
- Tiempo estimado de caminata a pie (`routeWalkingMinutes`).
- Disponibilidad de agua (`waterAvailability`).
- Nivel de cola y multitud (`queueLevel`).
- Frescura de la información (`freshness`).
- Nivel de confianza de la fuente (`confidenceLevel`).
- Perfil de accesibilidad física (`accessibilityInfo`).

> [!WARNING]
> **RECHAZO DE "MAGIC SCORES":**
> Se prohíbe cualquier fórmula del tipo `score = 0.40 * dist + 0.30 * queue`.
> La recomendación se basa en un pipeline determinista y explicable por fases justificadas mediante [`RecommendationReason`](lib/domain/recommendation/recommendation_reason.dart).

---

## 5. Resultados Explicables para la Interfaz de Usuario

El sistema modela hasta tres resultados diferenciados para la ciudadanía:

1. **RECOMENDADO (`recommended`):** Candidato con el balance más razonable entre disponibilidad reportada y distancia caminable. *(Se elimina el término "Recomendado Seguro")*.
2. **ALTERNATIVA (`alternatives`):** Opción viable en otra dirección o con menor congestión de cola.
3. **MÁS CERCANO (`nearestByDistance`):** Punto con la menor distancia física en la red vial, independientemente de que su estado live sea desconocido.

---

## 6. Tratamiento de Casos Extremos

### 6.1. Modo Sin Información Operacional (`onlyUnverifiedAvailable`)
Si ningún punto tiene telemetría o los datos carecen de política configurada:
- La aplicación **no falla ni inventa disponibilidades**.
- Muestra el punto físicamente más cercano según el catálogo base.
- Alerta clara: *"Sin información operacional en tiempo real. Se muestran los puntos según la infraestructura base oficial."*

### 6.2. Modo Sin Puntos Utilizables (`noRecommendationAvailable`)
Si todos los puntos alcanzables están intransitables o técnicamente aislados:
- `recommended` se establece explícitamente como `null`.
- Se genera narrativa honesta: *"No se pudo trazar una ruta caminable segura hacia los puntos conocidos."*

### 6.3. Distrito como Metadato (`DISTRICT_HARD_FILTER = NO`)
- **Regla Normativa:**
  > *"El distrito no excluye automáticamente candidatos. Un punto de otro distrito puede ser evaluado si no existe una regla institucional de área de servicio."*
- No existe preferencia a favor ni en contra de cruzar distritos; rige estrictamente la red peatonal caminable.
