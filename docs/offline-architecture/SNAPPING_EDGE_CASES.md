# VALIDACIÓN Y CASOS EXTREMOS DE SNAPPING — AGUACION (SUNASS)

## 1. Algoritmo de Snapping a Segmento con Coste Parcial

### 1.1 Estructura del Índice Espacial
El subsistema de snapping implementado en `EdgeSpatialGrid` (`lib/poc/offline_navigation/spatial/edge_spatial_grid.dart`) indexa las aristas del grafo peatonal en una cuadrícula bidimensional uniforme con celdas de **$0.0025^\circ$ ($\approx 275$ metros)**.

Cada celda almacena una lista compacta de índices de aristas. Para proyectar un punto arbitrario $P(\text{lat}, \text{lon})$:
1. Se localiza la celda central $(c_x, c_y) = (\lfloor \text{lon} / \Delta \rfloor, \lfloor \text{lat} / \Delta \rfloor)$.
2. Se exploran anillos concéntricos ($r = 0, 1, 2$, cubriendo hasta 25 celdas circundantes, equivalente a $\approx 825$ m).
3. Para cada arista $AB$ en las celdas, se proyecta ortogonalmente el punto $P$ sobre el segmento rectilíneo $AB$ mediante proyección en el plano tangencial local:
   $$t = \frac{-(ax \cdot vx + ay \cdot vy)}{vx^2 + vy^2}, \quad t \in [0, 1]$$
   Donde $t$ es el parámetro normalizado a lo largo del segmento ($t=0$ en el nodo $A$, $t=1$ en el nodo $B$).
4. Si la distancia geodésica perpendicular desde $P$ al punto proyectado $X = A + t(B - A)$ es menor o igual al umbral ($\text{thresholdMeters}$), se registra el candidato más cercano. Si ningún segmento se encuentra dentro del umbral, se devuelve `SnapStatus.snapNotFound`.

### 1.2 Tratamiento Riguroso de Puntos Virtuales $X$ e $Y$
A diferencia del enfoque preliminar donde el punto proyectado se redondeaba forzosamente al nodo $A$ o al nodo $B$, la implementación endurecida en este hito mantiene la posición virtual continua $X$ e inyecta los costes parciales exactos:

$$A \xleftarrow{\quad t \cdot L \quad} X \xrightarrow{\quad (1-t) \cdot L \quad} B$$

* **Entrada al grafo en Origen ($X$ sobre arista $AB$ de longitud $L_{orig}$):**
  * Coste hacia nodo $A$ ($u$): $d(X, A) = t_{orig} \cdot L_{orig}$
  * Coste hacia nodo $B$ ($v$): $d(X, B) = (1.0 - t_{orig}) \cdot L_{orig}$
  * El router $A^*$ inicializa su cola de prioridad con ambos extremos como puntos de arranque simultáneos.
* **Salida del grafo en Destino ($Y$ sobre arista $CD$ de longitud $L_{dest}$):**
  * Coste desde nodo $C$ ($u$): $d(C, Y) = t_{dest} \cdot L_{dest}$
  * Coste desde nodo $D$ ($v$): $d(D, Y) = (1.0 - t_{dest}) \cdot L_{dest}$
  * Durante la búsqueda, cualquier camino que alcance $C$ o $D$ puede conectarse a $Y$ sumando el coste residual correspondiente.
* **Travesía directa sobre el mismo segmento ($AB == CD$):**
  * Si origen y destino proyectan sobre la misma arista peatonal y esta no se encuentra bloqueada, la distancia peatonal sobre la vía es exactamente:
    $$D_{\text{red}}(X, Y) = |t_{orig} - t_{dest}| \cdot L_{orig}$$
    sin requerir exploración ciega del resto de la red.
* **Coste Total Puerta a Puerta:**
  $$D_{\text{total}} = d_{\text{snap}}(O, X) + D_{\text{red}}(X, Y) + d_{\text{snap}}(Y, \text{Dest})$$

---

## 2. Auditoría Experimental de Umbrales sobre los 433 Puntos SUNASS

Se ejecutó un análisis exhaustivo proyectando los **433 puntos oficiales de abastecimiento** sobre el grafo peatonal de Lima y Callao evaluando tres umbrales conservadores:

| Umbral Evaluado | Puntos Conectados | % Cobertura | SNAP_NOT_FOUND | % No Conectados | Distancia Media al Eje Vial | Distancia Máxima Observada |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **30 metros** | 388 / 433 | 89.6% | 45 | 10.4% | 9.0 m | 30.0 m |
| **50 metros** (Línea base) | 408 / 433 | **94.2%** | 25 | **5.8%** | 10.6 m | 49.6 m |
| **100 metros** | 426 / 433 | 98.4% | 7 | 1.6% | 13.1 m | 96.1 m |

### Hallazgos del Análisis de Umbral:
1. **Umbral de 50 metros:** Conecta con éxito al **94.2%** de los puntos oficiales con un promedio de desviación de solo 10.6 metros (típico ancho de vereda + retiro municipal). Los 25 puntos no conectados corresponden a reservorios o pozos ubicados en el interior de plantas de tratamiento cerradas de SEDAPAL (como La Atarjea) o en cimas de cerros sin vías peatonales digitalizadas en OSM.
2. **Umbral de 30 metros:** Es excesivamente estricto en urbanizaciones con retiros amplios o avenidas principales anchas, descartando 45 puntos válidos (10.4%).
3. **Umbral de 100 metros:** Conecta al 98.4%, pero introduce el riesgo de conectar un punto a una calle trasera o vía paralela separada por muros o propiedad privada.
4. **Recomendación:** Mantener **50 metros** como valor predeterminado seguro, permitiendo al usuario o al operador elevarlo a 100 m si se encuentra en zonas de retiro amplio.

---

## 3. Evaluación de 10 Casos Problemáticos

| # | Escenario Evaluado | Coordenadas | Descripción de Contexto | Resultado del Snapping | Comportamiento del Algoritmo |
| :-: | :--- | :---: | :--- | :--- | :--- |
| 1 | **Autopista (Vía de Evitamiento)** | (-12.041, -77.012) | Cerca de la Vía de Evitamiento | `SNAP_OK` (dist: 17.5 m) | Proyecta a la vía auxiliar / vereda peatonal adyacente (`edgeId: 915148`, segLen: 109.6 m), ignorando la calzada de alta velocidad si carece de tag peatonal. |
| 2 | **Panamericana Norte** | (-11.972, -77.068) | Cerca al trébol de Panamericana Norte | `SNAP_OK` (dist: 1.8 m) | Conecta inmediatamente a la berma/pasaje peatonal lateral (`edgeId: 490085`, segLen: 79.5 m). |
| 3 | **Río Rímac** | (-12.0405, -77.035) | Ribera del Río Rímac | `SNAP_NOT_FOUND` | La ribera carece de vía peatonal a menos de 50 m. El sistema **no inventa una conexión** y emite estado controlado. |
| 4 | **Costa Verde (Acantilado / Playa)** | (-12.125, -77.038) | Acantilado / bajada de baños | `SNAP_OK` (dist: 14.2 m) | Conecta a la bajada peatonal (`edgeId: 454449`). |
| 5 | **Parque grande (Campo de Marte)** | (-12.068, -77.042) | Explanada interior de gran parque | `SNAP_OK` (dist: 0.8 m) | Conecta al sendero peatonal interior (`highway=footway`, `edgeId: 643505`). |
| 6 | **Urbanización cerrada** | (-12.083, -76.965) | Calle interna residencial (Surco) | `SNAP_OK` (dist: 36.2 m) | Conecta a la calle interna residencial más próxima (`edgeId: 802233`). |
| 7 | **Calles densas (Centro Histórico)** | (-12.046, -77.032) | Jirón de la Unión | `SNAP_OK` (dist: 9.8 m) | Conecta limpiamente al eje peatonal (`edgeId: 429517`, segLen: 22.5 m). |
| 8 | **Periferia urbana (Lomas de Carabayllo)**| (-11.830, -77.020) | Borde urbano informal | `SNAP_OK` (dist: 43.5 m) | Conecta a la trocha carrozable/camino afirmado más cercano (`edgeId: 436112`). |
| 9 | **Más de 50 m sin vía (Estadio Nacional)** | (-12.0673, -77.0336) | Centro de campo deportivo (~85 m a calle) | `SNAP_NOT_FOUND` | El sistema descarta correctamente la proyección arbitraria al exceder 50 m. |
| 10 | **Entre dos calles paralelas** | (-12.048, -77.0305) | Manzana central entre dos jirones | `SNAP_OK` (dist: 3.6 m) | Proyecta ortogonalmente a la calle más cercana geométricamente (`edgeId: 994446`). |

---

## 4. Limitación Crítica de Accesibilidad Física

> [!WARNING]
> **Distancia geométrica $< 50$ m NO garantiza acceso físico real:**
> Una distancia geométrica perpendicular menor al umbral (ej. 15 metros) indica únicamente proximidad matemática al segmento en el plano cartográfico. En el entorno físico de Lima y Callao pueden existir:
> - Muros perimetrales y rejas de seguridad comunales no registradas en OSM;
> - Desniveles topográficos pronunciados (quebradas, acantilados de la Costa Verde);
> - Ríos o canales de regadío sin cruce puente habilitado;
> - Autopistas con muros jersey de concreto que impiden el cruce peatonal.
>
> Por este motivo, el sistema presenta la ruta como **"Ruta peatonal calculada según la información cartográfica disponible"** y jamás como "ruta garantizada" o "ruta sin obstáculos".
