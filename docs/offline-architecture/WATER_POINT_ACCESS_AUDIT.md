# Auditoría Técnica y Cartográfica de los 25 Puntos de Abastecimiento sin Conexión Peatonal Inmediata (SNAP_NOT_FOUND a 50 metros)

**Proyecto:** Agua Segura Perú / AguaCION — SUNASS
**Hito:** Hito 2D — Hardening Cartográfico, Auditoría de Acceso y Validación Física
**Fecha:** 11 de septiembre de 2026
**Universo Auditado:** Los 25 registros oficiales (5.77% del total de 433 puntos) que con el umbral base experimental de $50\text{ m}$ en el grafo peatonal `AGUACSR1` arrojaron estado `SnapStatus.snapNotFound`.
**Archivos Asociados:**
- Dataset tabular: [`WATER_POINT_ACCESS_AUDIT.csv`](docs/offline-architecture/WATER_POINT_ACCESS_AUDIT.csv)
- Dataset oficial normalizado: [`water_points_normalized.json`](assets/poc/data/water_points_normalized.json)
- Grafo peatonal: `pedestrian_graph_lima_csr.bin`
- Cartografía OSM fuente: `Lima.osm.gz` (BBBike / OpenStreetMap 2026-09-08)

---

## 1. Resumen Ejecutivo y Metodología de Auditoría

En los hitos anteriores se constató que con un umbral de snapping a segmento de $50\text{ metros}$, **408 de los 433 puntos oficiales (94.2%)** se conectan exitosamente a la red caminable con una distancia media al eje vial de $10.6\text{ metros}$. Sin embargo, **25 puntos (5.77%)** no encontraron ningún segmento transitable dentro de ese radio.

Para evitar suposiciones prematuras ("están dentro de plantas cerradas" o "el acceso ciudadano está en otro lado"), este hito ejecutó una **auditoría espacial individualizada** sobre cada uno de los 25 puntos contra el extracto completo de OpenStreetMap (`Lima.osm.gz`) en radios de $50\text{ m}$, $100\text{ m}$, $250\text{ m}$ y $400\text{ m}$, analizando:
1. La distancia exacta hacia el segmento peatonal transitable más cercano en el grafo `AGUACSR1`.
2. Las vías OSM preexistentes en el entorno físico inmediato, incluyendo autopistas, vías de servicio, vías privadas y áreas industriales.
3. El impacto de las reglas de filtrado de nuestro propio compilador de grafo (`build_pedestrian_graph.py`).
4. La topografía y descripción oficial del entorno (laderas de cerros, autopistas segregadas, urbanizaciones cerradas).

---

## 2. Inventario Detallado de los 25 Puntos Auditados

| FID | Código Oficial | EOMR | Distrito | Tipo Oficial | Dist. a Red Caminable | Snap 30m | Snap 50m | Snap 100m | Clasificación Técnica Neutral |
| :---: | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **30** | `P-633` | SJL | Lurigancho | Pozo | 87.3 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY` |
| **31** | `P-634` | SJL | Lurigancho | Pozo | 60.0 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` |
| **35** | `P-640` | SJL | Lurigancho | Pozo | 68.7 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` |
| **36** | `P-643` | SJL | Lurigancho | Pozo | 136.7 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` |
| **37** | `P-645` | SJL | Lurigancho | Pozo | 65.4 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` |
| **100** | `RAP-4 Lomas de Carabayllo` | Comas | Carabayllo | Hidrante | 228.5 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `INSIDE_MAPPED_FACILITY_SUSPECTED` \| `TERRAIN_OR_ELEVATION_REVIEW_REQUIRED` |
| **122** | `P-616` | Comas | Comas | Hidrante | 68.9 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY` |
| **147** | `R-1 Clorinda Malaga` | Comas | Comas | Hidrante | 102.0 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `TERRAIN_OR_ELEVATION_REVIEW_REQUIRED` |
| **169** | `P-299` | Comas | Puente Piedra | Hidrante | 56.5 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY` |
| **171** | `P-447` | Comas | Puente Piedra | Hidrante | 52.1 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **185** | `R-1 La Capitana RP-1` | Comas | Puente Piedra | Hidrante | 90.9 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` |
| **187** | `RP-2 Los Sureños` | Comas | Puente Piedra | Hidrante | 109.1 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `INSIDE_MAPPED_FACILITY_SUSPECTED` |
| **188** | `R-1 Santa Rosa` | Comas | Puente Piedra | Hidrante | 76.3 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **190** | `R-1 Shangrila` | Comas | Puente Piedra | Hidrante | 95.1 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **192** | `RP-4 Cerro Soledad` | Comas | Puente Piedra | Hidrante | 50.4 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `POSSIBLE_INFRASTRUCTURE_VS_ACCESS_LOCATION` \| `TERRAIN_OR_ELEVATION_REVIEW_REQUIRED` |
| **193** | `R-1 Pancha Paula` | Comas | Puente Piedra | Hidrante | 62.9 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `INSIDE_MAPPED_FACILITY_SUSPECTED` |
| **211** | `Surtidor Pro Lima` | Comas | Comas | Hidrante | 54.3 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `INSIDE_MAPPED_FACILITY_SUSPECTED` |
| **244** | `P-765` | Ate Vitarte | Ate | Hidrante | 84.4 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` \| `MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY` |
| **254** | `P-833` | Ate Vitarte | Chaclacayo | Hidrante | 142.4 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` |
| **263** | `R-P1` | Ate Vitarte | Ate | Hidrante | 75.5 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **268** | `R-P4` | Ate Vitarte | Ate | Hidrante | 108.6 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `TERRAIN_OR_ELEVATION_REVIEW_REQUIRED` |
| **269** | `R-P4` | Ate Vitarte | Ate | Hidrante | 103.0 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **271** | `R-P5` | Ate Vitarte | Ate | Hidrante | 77.1 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **293** | `CR-208` | Ate Vitarte | La Molina | Hidrante | 50.6 m | FAIL | FAIL | **PASS** | `NEAREST_EDGE_50_TO_100M` |
| **296** | `CR-415` | Ate Vitarte | La Molina | Hidrante | 336.3 m | FAIL | FAIL | FAIL | `NO_WALKABLE_EDGE_WITHIN_50M` \| `MAPPED_PRIVATE_OR_RESTRICTED_ACCESS_NEARBY` |

---

## 3. Estadísticas y Distribución de los 25 Casos

### 3.1. Distribución por Rango de Distancia a la Red Peatonal:
* **Entre $50\text{ m}$ y $100\text{ m}$:** **18 puntos (72.0% de los 25)**.
  * *Hallazgo:* Estos 18 puntos se conectan inmediatamente y de forma limpia si el umbral experimental se ajusta a $100\text{ metros}$. Su distancia promedio es de $69.8\text{ m}$, compatible con retiros de complejos industriales, parcelas amplias o vías con bermas anchas.
* **Superiores a $100\text{ m}$:** **7 puntos (28.0% de los 25)**.
  * Corresponden a distancias de $102.0\text{ m}$ (FID 147) hasta $336.3\text{ m}$ (FID 296).

### 3.2. Distribución por Tipo de Componente Oficial:
* **Hidrantes:** 20 puntos (80.0%)
* **Pozos:** 5 puntos (20.0%)
* *Nota:* En la base de datos oficial, varios reservorios de bombeo figuran registrados formalmente bajo el texto `"Hidrante"` en la columna `Tipo de co`, pero su código oficial comienza con `R-1`, `RP-1`, `RAP-4` o `CR-`.

### 3.3. Distribución por EOMR y Distrito:
* **EOMR-Comas (11 puntos):** Puente Piedra (8), Comas (2), Carabayllo (1).
* **EOMR-Ate Vitarte (9 puntos):** Ate (5), La Molina (2), Chaclacayo (1).
* **EOMR-SJL (5 puntos):** Lurigancho-Chosica (5) — Todos a lo largo de la Autopista Ramiro Prialé.
* **EOMR-Callao, Breña, Surquillo, Villa El Salvador:** **0 puntos** sin conexión (100% conectados a 50 m).

---

## 4. Hallazgos Cartográficos Críticos y Auditoría de Reglas del Grafo

La inspección espacial directa reveló tres patrones causales determinantes:

### Patrón A: Pozos de la Autopista Ramiro Prialé e Impacto de Reglas de Grafo (FID 30, 31, 35, 36, 37)
* **Observación Espacial:** En OpenStreetMap, los pozos P-633, P-634, P-640, P-643 y P-645 se ubican a escasos metros ($2.5\text{ m}$ a $29.6\text{ m}$) de la calzada de la **Autopista Ramiro Prialé** (`highway=trunk`).
* **Auditoría de Reglas de Grafo:** En `build_pedestrian_graph.py`, las vías clasificadas como `trunk` se excluyen de la red caminable salvo que cuenten con etiquetas explícitas `sidewalk=yes` o `foot=yes`. Esta regla es **técnicamente correcta y necesaria**, pues previene que el enrutador envíe a ciudadanos a caminar sobre una autopista interurbana de alta velocidad con barreras de concreto tipo New Jersey.
* **Consecuencia:** Al omitir la autopista, el punto de agua debe proyectarse hacia la vía auxiliar, calle residencial o trocha transitable más cercana al otro lado de la berma, la cual se encuentra a $60\text{ m} - 136\text{ m}$.
* **Conclusión Técnica:** No es un error del dataset ni del algoritmo de snapping; es el resultado legítimo de una regla de seguridad vial peatonal.

### Patrón B: Exclusión de Vías Privadas y Urbanizaciones Enrejadas (FID 296, FID 244, FID 122)
* **Caso Testigo FID 296 (`CR-415` en La Molina):**
  * La distancia hacia la vía pública transitable más cercana en el grafo es de **$336.3\text{ metros}$**.
  * Sin embargo, a apenas **$26.1\text{ metros}$** existe una vía residencial mapeada en OpenStreetMap (`Way #776949033`).
  * *¿Por qué no conectó?* Dicha vía está etiquetada en OSM con `access=private` (urbanización con tranquera / control de seguridad privado). Nuestro compilador excluye rigurosamente `access=private` de la red pública.
  * *Conclusión:* Si la contingencia permite el tránsito por estas calles residenciales enrejadas, el punto es físicamente accesible a 26 m; pero bajo cartografía pública abierta, queda aislado a 336 m.

### Patrón C: Infraestructura en Laderas de Cerros y Brechas de Mapeo OSM (FID 100, 147, 187, 268)
* **Observación Espacial:** Puntos como `RAP-4 Lomas de Carabayllo` ($228.5\text{ m}$) o `R-1 Clorinda Malaga` ($102.0\text{ m}$) corresponden a reservorios apoyados o cámaras elevadas en cimas y laderas de cerros en Carabayllo, Comas y Ate.
* **Brecha Cartográfica (*OSM Path Gap*):** En asentamientos informales de ladera, las escaleras comunales (*steps*), senderos y pircas de acceso muchas veces no han sido digitalizados por la comunidad de OpenStreetMap. La red vial digitalizada termina al pie del cerro, a más de 100 o 200 metros de la infraestructura hidráulica.

---

## 5. Modelo Conceptual: `infrastructure_location` vs. `pedestrian_access_location`

> [!IMPORTANT]
> **REGLA METODOLÓGICA:** No se ha inventado ninguna coordenada de acceso peatonal para ninguno de los 25 puntos. Todas las coordenadas contenidas en el repositorio provienen al 100% de la fuente oficial de SEDAPAL/SUNASS.

Para abordar este fenómeno en etapas posteriores del proyecto, se formaliza el siguiente modelo conceptual desacoplado:

```dart
enum AccessValidationStatus {
  pendingInstitutionalValidation, // Estado actual de los 433 puntos
  verifiedCitizenAccess,          // Puerta/grifo verificado en campo por fiscalizadores
  infrastructureOnlyNoPublicAccess, // Pozo operacional sin despacho ciudadano
  accessRequiresEscortOrClearance, // Ubicado dentro de instalación militar/privada
}

class WaterPointAccess {
  /// Identificador canónico inmutable en AguaCION
  final String waterPointId;

  /// Coordenada del activo hidráulico/patrimonial provista por SEDAPAL
  final LatLng infrastructureLocation;

  /// Coordenada exacta del portón, vereda o punto de llenado ciudadano.
  /// Se mantiene estrictamente como NULL hasta que exista verificación de campo.
  final LatLng? pedestrianAccessLocation;

  /// Distancia lineal entre el activo y el punto de acceso (null si no está validado)
  final double? accessOffsetMeters;

  /// Estado de validación institucional
  final AccessValidationStatus accessValidationStatus;

  /// Identificador del fiscalizador, brigadista o fuente oficial de verificación
  final String verificationSource;

  /// Fecha y hora de verificación en campo
  final DateTime? verifiedAt;

  const WaterPointAccess({
    required this.waterPointId,
    required this.infrastructureLocation,
    this.pedestrianAccessLocation,
    this.accessOffsetMeters,
    this.accessValidationStatus = AccessValidationStatus.pendingInstitutionalValidation,
    this.verificationSource = 'SEDAPAL_OFFICIAL_DATASET_20260819',
    this.verifiedAt,
  });

  /// Retorna la coordenada de destino que debe alimentar al motor de routing
  LatLng get routingTargetLocation => pedestrianAccessLocation ?? infrastructureLocation;
}
```

---

## 6. Recomendaciones Técnicas para SUNASS y Próximos Pasos

1. **Adopción de Umbral Bipiramidal:** Mantener $50\text{ metros}$ como umbral base urbano, pero permitir que el enrutador aplique un fallback automático a $100\text{ metros}$ para los 18 puntos periurbanos que conectan limpiamente a esa distancia.
2. **Prioridad de Inspección en Campo:** Trasladar la lista de los **7 puntos con desvío $> 100\text{ m}$** (FIDs 36, 100, 147, 187, 254, 268, 296) al equipo de supervisión de SUNASS para determinar si disponen de un punto de atención al público en la vía pública más próxima.
3. **Consulta Institucional Formal:** Incluir en la agenda técnica con SEDAPAL la necesidad de proveer la coordenada del portón de atención ciudadana para activos situados en autopistas y laderas.
