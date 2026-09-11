# INVESTIGACIÓN Y VALIDACIÓN: BÚSQUEDA ADAPTATIVA DE PUNTOS DE AGUA

## 1. Justificación Matemática y Corrección de la Premisa $N = 5$

### 1.1 Invalidez Teórica de la Regla Fija $N = 5$
El prototipo preliminar adoptó la heurística arbitraria de calcular la ruta peatonal hacia los $N = 5$ puntos más cercanos en distancia euclidiana/Haversine. Dicha regla se justificó empíricamente al observar que para un punto de prueba en Los Olivos, $N=5$, $N=10$ y $N=20$ arrojaban el mismo ganador.

Sin embargo, como se reconoció formalmente en el Hito 2C:
1. Una observación empírica puntual en un distrito **no constituye demostración matemática** aplicable a toda el área metropolitana de Lima y Callao.
2. En zonas urbanas con barreras geográficas o infraestructurales severas (ríos sin puentes inmediatos como el Río Rímac, vías expresas segregadas como Evitamiento o Vía Expresa Paseo de la República, líneas de tren, o cerros en distritos como Independencia, El Agustino, San Juan de Lurigancho o Ate), los 5 o 10 puntos geodésicamente más cercanos pueden encontrarse al otro lado de la barrera, exigiendo desvíos de varios kilómetros.
3. Un punto situado geodésicamente en la posición 6 u 8 podría encontrarse sobre la misma vereda accesible, siendo inalcanzable para una búsqueda fija con $N = 5$.

Por consiguiente, la regla $N = 5$ ha sido **definitivamente eliminada y reemplazada** por un algoritmo adaptativo con criterio de parada matemáticamente exacto.

---

## 2. Formulación de `AdaptiveWaterPointSearch`

### 2.1 Cota Geodésica Inferior y Desigualdad Triangular
Sea $O$ el origen del usuario en coordenadas $(\text{lat}_O, \text{lon}_O)$ y sea $P_k$ el $k$-ésimo punto de abastecimiento oficial en $(\text{lat}_k, \text{lon}_k)$.
Sea $h(O, P_k)$ la distancia ortodrómica (Haversine) directa sobre la esfera terrestre entre $O$ y $P_k$.

Por definición de geodésica en un espacio métrico riemanniano (o métrica sobre una superficie esférica/elipsoidal), la distancia en línea recta representa el **ínfimo absoluto** de la longitud de cualquier curva continua diferenciable a trozos que conecte $O$ con $P_k$:
$$\forall \text{ curva } C \text{ de } O \text{ a } P_k, \quad \text{Longitud}(C) \ge h(O, P_k)$$

En nuestro sistema de navegación, la ruta calculada por el router $A^*$ $D_{\text{route}}(O, P_k)$ está compuesta por:
1. El segmento perpendicular desde el origen $O$ al punto proyectado $X$ en la calle: $d_{\text{snap}}(O, X)$
2. La secuencia de segmentos peatonales de la red vial desde $X$ hasta el punto proyectado $Y$: $D_{\text{red}}(X, Y)$
3. El segmento perpendicular desde $Y$ hasta el punto de agua $P_k$: $d_{\text{snap}}(Y, P_k)$

La concatenación de estos tres tramos conforma una trayectoria poligonal continua en el espacio físico desde $O$ hasta $P_k$. Por la desigualdad triangular generalizada:
$$D_{\text{route}}(O, P_k) = d_{\text{snap}}(O, X) + D_{\text{red}}(X, Y) + d_{\text{snap}}(Y, P_k) \ge h(O, P_k)$$

### 2.2 Regla de Parada Temprana Exacta
Sea $S = [P_0, P_1, P_2, \dots, P_{M-1}]$ la lista ordenada ascendentemente por su distancia Haversine al origen:
$$h(O, P_0) \le h(O, P_1) \le h(O, P_2) \le \dots \le h(O, P_{M-1})$$

Sea $D_{\text{best}}$ la menor distancia de ruta peatonal real encontrada hasta el momento entre los candidatos ya evaluados mediante $A^*$.

**Teorema de Parada Temprana:**
Si al evaluar el siguiente candidato candidato $P_k$ se cumple:
$$h(O, P_k) \ge D_{\text{best}}$$
Entonces la búsqueda puede **detenerse inmediatamente**, garantizando que el punto que originó $D_{\text{best}}$ es el óptimo global irrefutable en toda la red disponible.

**Demostración:**
Para cualquier candidato posterior $P_j$ con $j \ge k$, por la ordenación monótona de $S$:
$$h(O, P_j) \ge h(O, P_k)$$
Aplicando la cota geodésica inferior:
$$D_{\text{route}}(O, P_j) \ge h(O, P_j) \ge h(O, P_k) \ge D_{\text{best}}$$
Por lo tanto:
$$\forall j \ge k, \quad D_{\text{route}}(O, P_j) \ge D_{\text{best}}$$
Ningún candidato posterior puede tener una ruta peatonal estrictamente menor que $D_{\text{best}}$. La búsqueda se detiene de forma segura. $\blacksquare$

---

## 3. Validación contra Oráculo Exhaustivo de 433 Puntos

Para comprobar experimentalmente que `AdaptiveWaterPointSearch` jamás descarta prematuramente a un ganador verdadero, se implementó un **Oráculo de Test Exhaustivo** (`searchExhaustive`) que evalúa ciegamente la ruta $A^*$ hacia la totalidad de los 433 puntos oficiales sin criterio de parada temprana.

### 3.1 Escenarios Evaluados
Se probaron orígenes distribuidos a lo largo de Lima Norte, Lima Centro, Lima Este, Lima Sur, Callao, límites distritales y zonas de alta y baja densidad.

### 3.2 Resultados y Coincidencia
En el 100% de los escenarios analizados con origen válido:
$$\text{Ganador}(\text{Adaptive}) \equiv \text{Ganador}(\text{Exhaustive})$$
$$\text{Distancia Peatonal}(\text{Adaptive}) \equiv \text{Distancia Peatonal}(\text{Exhaustive})$$

### 3.3 Reducción de Carga Computacional
* **Candidatos evaluados en búsqueda exhaustiva:** 433 rutas $A^*$ por consulta.
* **Candidatos evaluados en búsqueda adaptativa:** 1 a 4 candidatos $A^*$ típicos (p50 = 1, p95 = 4).
* **Ahorro de cómputo en CPU:** Reducción de más del **98.8%** en llamadas al algoritmo $A^*$, logrando tiempos de respuesta inferiores a 5 ms en desktop Dart y menos de 15 ms en hardware móvil.

---

## 4. Divergencias Demostradas: Haversine vs. Ruta Peatonal Real

El benchmark identificó casos contundentes donde la selección por línea recta (Haversine) habría conducido al ciudadano a un punto drásticamente peor o inaccesible:

1. **Ate Vitarte (Lima Este):**
   * Haversine eligió: `WP-SED-ATE-0B721B0FA9` (aparentemente más cercano en recta).
   * Ruta real a pie hacia el punto Haversine: $> 6,380$ m (debido a la topografía de cerros y segregación de vías rápidas).
   * Ganador por Grafo Peatonal: `WP-SED-ATE-EDFDF729AD` (distancia real a pie: **746.2 m**).
   * **Ahorro peatonal efectivo:** **5,638 metros** (más de 1 hora de caminata en emergencia).
2. **Los Olivos (Lima Norte):**
   * Haversine eligió: `WP-SED-COM-25F4024735` (en línea recta al otro lado de la Panamericana Norte).
   * Ganador por Grafo Peatonal: `WP-SED-COM-F13489AE32` (distancia real a pie: 1,606.3 m).
   * **Ahorro peatonal efectivo:** **72 metros** caminando por cruce peatonal habilitado.
3. **Comas (Lima Norte):**
   * Haversine eligió: `WP-SED-COM-0005D42941`.
   * Ganador por Grafo Peatonal: `WP-SED-COM-E03F51ED57`.
   * **Ahorro peatonal efectivo:** **13 metros**.

**Conclusión:** La distancia euclidiana/Haversine es una heurística útil **únicamente para ordenar candidatos iniciales**, pero es inadmisible como criterio final de selección en un entorno urbano real de emergencia.
