# Cuestionario Institucional para SEDAPAL y SUNASS

**Proyecto:** Agua Segura Perú / AguaCION
**Fecha:** 11 de septiembre de 2026 (Actualizado Hito 3A)
**Finalidad:** Resolver vacíos semánticos, inconsistencias operacionales y definiciones críticas de salud pública y contingencia identificadas durante la auditoría del dataset oficial de 433 puntos provisionales fijos (Informe N° 052-2026-EOMR-SJL y Carta N° 1089-2026-GG), y definir las reglas de gobernanza para el modelo operacional de emergencias.

---

## 1. Cuestionario Operacional y de Gobernanza (Hito 3A)

Las 22 preguntas fundamentales requeridas para la operación del motor de estados y recomendación han sido formalmente categorizadas según su impacto en el ciclo de desarrollo:

- **`BLOCKER_FOR_OPERATIONAL_ENGINE`:** Impide definir el comportamiento determinista del motor de recomendación si no cuenta con definición oficial.
- **`IMPORTANT_FOR_PILOT`:** Indispensable para el piloto controlado de campo y las pruebas operativas en Lima y Callao.
- **`FUTURE`:** Requerimiento de integración a mediano/largo plazo para la geodatabase corporativa.

---

### Tabla Resumen de Clasificación

| N° | Pregunta Operacional / Institucional | Clasificación Técnica | Impacto en AguaCION |
| :---: | :--- | :--- | :--- |
| 1 | ¿Quién tiene la potestad formal de declarar un punto como operativo o inoperativo durante una emergencia? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Define la autoridad de escritura en `OperationalStatus`. |
| 2 | ¿Qué entidad o funcionario actualiza la disponibilidad de agua en tiempo real? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Define la fuente válida para `WaterAvailability`. |
| 3 | ¿Con qué periodicidad mínima y máxima se emitirán las actualizaciones de estado operacional? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Define los parámetros de `FreshnessPolicy`. |
| 4 | ¿Cuál es la unidad oficial de la columna `Capacidad` (L/s, m³/h, m³)? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Prohíbe inventar unidades; previene cálculos erróneos de caudal. |
| 5 | ¿`Capacidad` representa caudal instantáneo de bombeo, volumen de reserva o caudal medio? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Condiciona el modelo hidráulico de duración del agua. |
| 6 | ¿Existen definiciones oficiales y normadas que distingan `Situación` de `Estado`? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Resuelve la semántica de los 111 puntos ambiguos. |
| 7 | ¿Los 111 puntos `Operativo` pero `En reserva` pueden despachar agua a la población en una emergencia? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Define si se incluyen como candidatos recomendables. |
| 8 | ¿Existen umbrales o niveles oficiales de saturación de cola (personas en espera / tiempo)? | `IMPORTANT_FOR_PILOT` | Calibra los estados ordinales de `QueueLevel`. |
| 9 | ¿SEDAPAL o los operadores registran formalmente el tiempo de espera estimado en minutos? | `IMPORTANT_FOR_PILOT` | Determina si `estimatedWaitMinutes` será poblado en terreno. |
| 10 | ¿Puede un ciudadano desplazarse libremente a un punto de abastecimiento ubicado en otro distrito? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Ratifica la regla `DISTRICT_HARD_FILTER = NO`. |
| 11 | ¿Existen sectores o polígonos oficiales de atención asignados a cada punto de agua? | `IMPORTANT_FOR_PILOT` | Define si el campo opcional `serviceAreaId` debe activarse. |
| 12 | ¿Cómo se incorporan operativamente los puntos provisionales temporales (e.g. tanques vejiga)? | `IMPORTANT_FOR_PILOT` | Permite activar la abstracción `WaterSourceKind.temporaryStation`. |
| 13 | ¿Cómo se gestiona y coordina el reparto de agua mediante camiones cisterna? | `IMPORTANT_FOR_PILOT` | Establece el modelo de datos de `TankerTruckProfile`. |
| 14 | ¿Dispone el COE SEDAPAL de un servicio digital o feed automatizado para emergencias? | `IMPORTANT_FOR_PILOT` | Permite el consumo de eventos oficiales sin procesamiento manual. |
| 15 | ¿Existe un Feature Service o API REST en la plataforma GeoSUNASS para sincronización? | `IMPORTANT_FOR_PILOT` | Define el protocolo de transporte para el módulo *Store & Forward*. |
| 16 | ¿Quién es la autoridad encargada de reportar vías bloqueadas o intransitables (INDECI / PNP / Serenazgo)? | `IMPORTANT_FOR_PILOT` | Alimenta el modelo `Incident` y el bloqueo de aristas viales. |
| 17 | ¿Toda la información operacional es de carácter público o existen restricciones de orden público? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Previene contingencias de seguridad ciudadana por aglomeración. |
| 18 | ¿Qué fuente prevalece legalmente si existe contradicción flagrante entre reportes oficiales y ciudadanos? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Define la política de resolución en `SourceConflict`. |
| 19 | ¿Cuál es la ventana máxima de vigencia temporal admisible para cada tipo de dato antes de considerarlo obsoleto? | `BLOCKER_FOR_OPERATIONAL_ENGINE` | Fija los valores por defecto de `FreshnessPolicy`. |
| 20 | ¿Existe la obligación legal o normativa de mantener un registro inmutable de auditoría de cada cambio de estado? | `IMPORTANT_FOR_PILOT` | Justifica y formaliza el uso de `OperationalEvent`. |
| 21 | ¿Los operadores de campo requieren credenciales criptográficas y roles diferenciados para emitir reportes? | `IMPORTANT_FOR_PILOT` | Define los perfiles de seguridad en el modelo de actores. |
| 22 | ¿Asignará SEDAPAL un Identificador Único de Activo (Asset ID corporativo) a cada uno de los 433 puntos? | `FUTURE` | Reemplazará el hash sintético temporal `water_point_id`. |

---

## 2. Detalle de Preguntas Críticas y Hallazgos Previos de Auditoría

### PREGUNTA 1: Definición y Magnitud de la `Capacidad`
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Hallazgo:** 303 puntos registran exactamente `15.00`, 89 registran `2.00` y 38 registran `8.60`. Ningún documento oficial menciona la definición física de este valor.
- **Riesgo Ciudadano:** Si la app interpreta erróneamente un caudal de 15 L/s como 15 m³ de reserva total, la estimación de duración del agua y atención familiar será completamente falsa.
- **Acción en AguaCION:** Se mantiene `capacityRaw` como String sin inventar unidades de medida.

---

### PREGUNTA 2: Unidad de Medida Oficial de la `Capacidad`
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Pregunta:** ¿Cuál es la unidad de medida oficial de la columna `Capacidad`? ¿Se trata de caudal en litros por segundo ($\text{L/s}$), caudal en metros cúbicos por hora ($\text{m}^3/\text{h}$), o volumen acumulado de almacenamiento en metros cúbicos ($\text{m}^3$)?
- **Acción en AguaCION:** Hasta contar con respuesta oficial por escrito, el sistema mantiene la unidad como indeterminada y no proyecta tiempos de agotamiento.

---

### PREGUNTA 3: Diferencia Institucional entre `Situación` y `Estado`
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Hallazgo Crítico:** Existen **111 puntos** que figuran como `Situación = Operativo` pero `Estado = En reserva` (32 en Callao y 79 en Comas; en Comas existe adicionalmente 1 punto `En reparación` con estado `En reserva`, totalizando 80 puntos en reserva en dicho EOMR). Asimismo, existen 8 puntos `Situación = En implementación` pero `Estado = Activo` en SJL.
- **Dilema en la App:** ¿Debe AguaCION mostrar al ciudadano los puntos `En reserva` durante las primeras 72 horas del desastre, o solo los puntos `Activo`? Si un ciudadano camina 1.5 km a un punto clasificado como "Operativo" y lo encuentra cerrado con candado porque estaba "En reserva", se genera frustración y riesgo físico.

---

### PREGUNTA 4: Gobernanza de Estados Operacionales en Terreno
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Pregunta:** ¿Quién puede declarar formalmente un punto como operativo o inoperativo? ¿Un jefe de cuadrilla en sitio, el COE SEDAPAL o el regulador SUNASS?
- **Implicancia:** Define la matriz de autorización en `SourceType` y las reglas de precedencia de fuentes.

---

### PREGUNTA 5: Libertad de Abastecimiento vs. Jurisdicción Vecinal
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Pregunta:** ¿Puede un ciudadano abastecerse en cualquier punto provisional sin importar su distrito de residencia, o SEDAPAL/INDECI restringirán el reparto únicamente a vecinos empadronados o residentes del sector?
- **Riesgo:** Si un vecino de Rímac o Jesús María (distritos que tienen 0 puntos fijos en la lista) camina a un hidrante de Breña o Cercado de Lima, ¿se le permitirá retirar agua?
- **Decisión en AguaCION:** `DISTRICT_HARD_FILTER = NO` (ADR-006).

---

### PREGUNTA 6: Población Asignada y Capacidad de Atención Simultánea
- **Clasificación:** `IMPORTANT_FOR_PILOT`
- **Pregunta:** ¿Existe una población objetivo calculada para cada uno de los 433 puntos? ¿Cuántos grifos o bocas de salida simultáneas posee cada punto (en particular las cámaras con *Manifolds*)?
- **Implicancia:** Esencial para calcular tiempos de espera estimados en cola y alertar sobre congestión.

---

### PREGUNTA 7: Coordenada de Infraestructura Hidráulica vs. Acceso Peatonal Ciudadano
- **Clasificación:** `BLOCKER_FOR_OPERATIONAL_ENGINE`
- **Hallazgo:** La auditoría espacial demostró que la coordenada oficial corresponde al activo de ingeniería (tubería, bomba, cabezal) y no al portón peatonal, ocasionando que 25 puntos queden a más de 50 m de la vía transitable.
- **Solución en AguaCION:** Desacoplamiento explícito entre `infrastructureLocation` y `pedestrianAccessLocation`.

---

### PREGUNTA 8: Protocolo de Abastecimiento para los 14 Distritos sin Puntos Fijos
- **Clasificación:** `IMPORTANT_FOR_PILOT`
- **Pregunta:** Ancón, Jesús María, La Perla, Lurín, Magdalena del Mar, Mi Perú, Pachacámac, Pucusana, Punta Hermosa, Punta Negra, Rímac, San Bartolo, Santa María del Mar y Santa Rosa carecen de puntos fijos oficiales en el catálogo analizado. ¿Cuál es el protocolo formal previsto por SEDAPAL (cisternas, derivación interdistrital, plantas móviles)?
