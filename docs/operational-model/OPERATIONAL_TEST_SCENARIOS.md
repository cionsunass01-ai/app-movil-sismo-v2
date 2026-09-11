# Escenarios de Prueba Conceptuales del Modelo Operacional

**Proyecto:** AguaCION / Agua Segura Perú (SUNASS)
**Hito:** Hito 3A
**Fecha:** 11 de septiembre de 2026
**Finalidad:** Definir la matriz de 12 casos conceptuales de emergencia que validan el comportamiento del modelo de dominio antes del desarrollo del motor de recomendación de Hito 3B.
**Convención:** Cuando una decisión depende estrictamente de una norma o protocolo no emitido por SUNASS/SEDAPAL, se declara formalmente: `EXPECTED_DECISION = PENDING_POLICY`.

---

## Matriz de Escenarios Conceptuales

### CASO 1: Proximidad con Estado Desconocido vs. Mayor Distancia con Disponibilidad Confirmada
- **Situación:**
  - **Punto A:** Distancia calculada $1.0\text{ km}$. Estado operacional: `UNKNOWN` (sin reporte reciente).
  - **Punto B:** Distancia calculada $1.3\text{ km}$. Estado: `AVAILABLE`, nivel de confianza: `HIGH_CONFIDENCE`, frescura: `FRESH` (actualizado hace 15 minutos por operador de campo).
- **Información que Requiere el Motor:**
  - Distancia peatonal real por grafo (A*).
  - Estado de frescura evaluado según `FreshnessPolicy`.
  - Nivel de confianza de la fuente (`ConfidenceLevel`).
- **Comportamiento Diseñado:**
  - La interfaz de usuario presenta simultáneamente:
    - **RECOMENDADO:** Punto B ($1.3\text{ km}$), con justificación `confirmedWaterAvailable` y advertencia de que requiere $300\text{ m}$ adicionales de caminata.
    - **MÁS CERCANO:** Punto A ($1.0\text{ km}$), con advertencia explícita: *"Estado no confirmado; verificar en sitio bajo propio criterio"*.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 2: Punto Más Cercano Confirmado Cerrado vs. Segundo Punto Disponible
- **Situación:**
  - **Punto A ($450\text{ m}$):** Estado `CLOSED` confirmado por boletín oficial de SEDAPAL hace 20 minutos (rotura de tubería de purga).
  - **Punto B ($1.1\text{ km}$):** Estado `AVAILABLE`, confirmado activo.
- **Información que Requiere el Motor:**
  - `operationalStatus == closed` o `accessStatus == closed`.
  - Exclusión inmediata de Punto A mediante *Hard Filter*.
- **Comportamiento Diseñado:**
  - Punto A queda descalificado como recomendación de abastecimiento con razón `ExclusionReason.confirmedClosed`.
  - **RECOMENDADO:** Punto B ($1.1\text{ km}$), con justificación `alternativeDueToClosure` (explicando: *"El punto más cercano en Jr. X está cerrado por mantenimiento"*).
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 3: Dos Puntos Disponibles con Diferente Saturación de Cola
- **Situación:**
  - **Punto A ($800\text{ m}$):** `AVAILABLE`, pero con `queueLevel = HIGH` o `SATURATED` (reporte de más de 120 personas en fila).
  - **Punto B ($1.2\text{ km}$):** `AVAILABLE`, con `queueLevel = LOW` (reporte de atención fluida, 10 personas).
- **Información que Requiere el Motor:**
  - Comparativa entre tiempo de caminata adicional vs. tiempo estimado de espera en cola.
- **Comportamiento Diseñado:**
  - No se aplica un cálculo multiplicativo ciego.
  - La app presenta:
    - **RECOMENDADO:** Punto B ($1.2\text{ km}$), con justificación `lowerQueueLevel` si la cola en A excede el umbral crítico.
    - **ALTERNATIVA:** Punto A ($800\text{ m}$), señalando: *"Más cerca pero con alta congestión de personas"*.
- **Estado Institucional:** `EXPECTED_DECISION = PENDING_POLICY` (SUNASS debe validar si en emergencia extrema se prioriza dispersar a la multitud o minimizar caminata física).

---

### CASO 4: Información Oficial Antigua vs. Múltiples Reportes Ciudadanos Recientes
- **Situación:**
  - Boletín oficial de SEDAPAL de hace 18 horas indicaba punto `OPERATIONAL`.
  - En los últimos 30 minutos, 18 reportes ciudadanos concordantes indican `POINT_CLOSED` o `NO_WATER`.
- **Información que Requiere el Motor:**
  - Detección de conflicto temporal y de fuentes (`SourceConflict` con tipo `officialVsCitizen`).
  - Evaluación de frescura: la fuente oficial está en estado `STALE` o `EXPIRED`, mientras que los reportes ciudadanos están `FRESH`.
- **Comportamiento Diseñado:**
  - El sistema **no borra** la mención del punto ni oculta el dato oficial, pero suspende la recomendación activa e inserta una advertencia de conflicto de alta visibilidad:
    *"Advertencia: Reportes ciudadanos recientes indican falta de agua a pesar de la programación oficial previa."*
- **Estado Institucional:** `EXPECTED_DECISION = PENDING_POLICY` (Requiere protocolo formal de triaje de reportes ciudadanos entre SUNASS y SEDAPAL).

---

### CASO 5: Todos los Datos Operacionales en Estado STALE o EXPIRED
- **Situación:**
  - Pasaron más de 8 horas desde la última emisión de telemetría o boletín. Ningún punto tiene reportes frescos.
- **Información que Requiere el Motor:**
  - `status.evaluateFreshness(now) == FreshnessState.stale` o `expired` para todos los registros.
- **Comportamiento Diseñado:**
  - La aplicación entra en modo de contingencia:
    - Resultado: `RecommendationOutcome.onlyUnverifiedAvailable`.
    - No inventa que los puntos están operativos.
    - Notificación al ciudadano: *"Última actualización hace más de 8 horas. Se muestran los puntos según infraestructura base, pero el servicio no está garantizado."*
    - Ordena las opciones por ruta peatonal más corta (`shortestWalkableRoute`).
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 6: Escenario de Cero Conectividad (100% Offline)
- **Situación:**
  - Terremoto destructivo. Redes celulares y Wi-Fi totalmente caídas. El usuario abre la app por primera vez tras el sismo.
- **Información que Requiere el Motor:**
  - Catálogo embebido local de 433 puntos.
  - Tiles vectoriales locales PMTiles y grafo peatonal CSR en almacenamiento interno.
  - GPS autónomo del teléfono (GNSS).
- **Comportamiento Diseñado:**
  - Funcionamiento autónomo inmediato: cálculo de ruta peatonal A* en menos de 5 ms, snapping a 50 m, mapa renderizado sin conexión.
  - El motor informa que el estado dinámico es `UNKNOWN` y provee el punto transitable físicamente más cercano.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN` (Validado físicamente en Hitos 2C y 2D).

---

### CASO 7: Conectividad Intermitente ("Aparece y Desaparece")
- **Situación:**
  - El ciudadano intenta enviar 2 reportes de saturación mientras camina. La señal 3G/4G parpadea por breves segundos de forma esporádica.
- **Información que Requiere el Motor:**
  - Transacciones atómicas en `OutboxItem` gestionadas con SQLite/Drift.
  - Identificador idempotente `deviceGeneratedId`.
- **Comportamiento Diseñado:**
  - Los reportes se almacenan de inmediato en la base de datos local como `pending`.
  - Un servicio de sincronización (*Store & Forward*) intenta la transmisión en ráfaga cuando detecta enlace, sin bloquear jamás la UI ni duplicar registros en caso de cortes a mitad del handshake HTTP.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 8: Punto en Distrito Vecino con Mejor Ruta Peatonal
- **Situación:**
  - Ciudadano ubicado en el límite de Jesús María (distrito con 0 puntos registrados).
  - El punto de abastecimiento más cercano está a $750\text{ m}$ en Breña o Cercado de Lima.
- **Información que Requiere el Motor:**
  - Grafo vial transfronterizo.
  - Ausencia de restricciones distritales (`DISTRICT_HARD_FILTER = NO`).
- **Comportamiento Diseñado:**
  - El motor recomienda el punto de Breña sin bloquear al usuario, informando la distancia y tiempo de caminata real.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN` (Validado en ADR-006).

---

### CASO 9: Ruta Peatonal Bloqueada por Incidente (Derrumbe o Inundación)
- **Situación:**
  - Un sismo causa el colapso de una casona o caída de cables en la vía de acceso principal hacia el punto más cercano.
  - Se registra un `Incident` con `type = roadBlock`, afectando las aristas viales 1420 y 1421.
- **Información que Requiere el Motor:**
  - Lista de aristas deshabilitadas en el grafo peatonal (`disabledEdges`).
  - Recálculo dinámico con A*.
- **Comportamiento Diseñado:**
  - El motor recalcula la ruta evadiendo las aristas bloqueadas.
  - Si el desvío hace que otro punto sea más corto, la recomendación cambia transparentemente al punto alternativo informando: *"Ruta recalculada por bloqueo en vía pública"*.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 10: Ningún Punto Tiene Ruta Peatonal Transitables
- **Situación:**
  - Ciudadano aislado en una quebrada o zona ribereña cuyos accesos peatonales están cortados en el grafo, o fuera del radio de snapping de 50 m.
- **Información que Requiere el Motor:**
  - Falla en el snapping inicial o A* devuelve camino nulo para todos los candidatos evaluados.
- **Comportamiento Diseñado:**
  - El motor devuelve formalmente:
    - `outcome = RecommendationOutcome.allPointsUnreachable`
    - `recommended = null`
    - Narrativa: *"No se pudo trazar una ruta caminable segura hacia los puntos de abastecimiento conocidos. Permanezca en un lugar seguro o contacte a los servicios de emergencia."*
  - Prohibido trazar líneas rectas geodésicas engañosas a través de cerros o abismos.
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`

---

### CASO 11: Contradicción Severa de Fuentes en un Mismo Intervalo
- **Situación:**
  - Fuente oficial institucional (SEDAPAL) emite comunicado indicando: *"Punto Operativo 24 Horas"*.
  - Paralelamente, una cuadrilla de serenazgo municipal y 15 ciudadanos reportan que el grupo electrógeno sufrió una falla mecánica y no hay bombeo.
- **Información que Requiere el Motor:**
  - Estructura `SourceConflict` con `ConflictType.officialVsCitizen`.
- **Comportamiento Diseñado:**
  - El sistema no arbitra unilateralmente quién tiene la verdad mediante algoritmos opacos.
  - Clasifica el punto como `CONFLICTING_INFORMATION`, mantiene la decisión operacional como `PENDING_POLICY`, muestra ambas observaciones al usuario para transparencia y puede ofrecer un punto alternativo cercano con estado no controvertido.
- **Estado Institucional:** `EXPECTED_DECISION = PENDING_POLICY` (SUNASS debe fijar la jerarquía de desempate en emergencias).

---

### CASO 12: Dataset Instalado con Varios Días o Semanas sin Actualizar
- **Situación:**
  - La aplicación fue instalada hace 3 semanas y nunca volvió a conectarse a Internet.
- **Información que Requiere el Motor:**
  - `DatasetMetadata.isStale(now, threshold) == true`.
- **Comportamiento Diseñado:**
  - La app sigue funcionando plenamente con el catálogo base de 433 puntos y el grafo offline.
  - Muestra una barra de estado informativa:
    *"Catálogo base: Versión 2026.08.19 (hace 21 días). Se recomienda actualizar cuando disponga de conexión."*
- **Estado Institucional:** `CONFIRMED_TECHNICAL_DESIGN`
