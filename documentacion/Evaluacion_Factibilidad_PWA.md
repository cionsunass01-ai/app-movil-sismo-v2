# Análisis de Factibilidad: Arquitectura PWA vs. Nativa (App AguaCION)

## 1. Resumen Ejecutivo
El presente documento evalúa la viabilidad técnica y operativa de implementar el proyecto **AguaCION** (visor de mapas y ruteo peatonal 100% offline para escenarios de sismos) bajo la arquitectura de una **Progressive Web App (PWA)**, tal como fue recomendado inicialmente por la Oficina de Tecnologías de la Información (OTI).

Si bien la recomendación de la OTI se alinea con los estándares modernos de modernización digital del Estado (cuyo objetivo es reducir la fricción de publicación en las tiendas de Apple y Google), **la naturaleza crítica y de contingencia (Disaster Response)** de esta aplicación hace que el modelo PWA presente vulnerabilidades estructurales que ponen en riesgo la disponibilidad del servicio durante una emergencia real.

Por lo tanto, la recomendación técnica final es **mantener la arquitectura Nativa (Flutter)**.

---

## 2. Puntos a Favor de la Arquitectura PWA (Factibilidad Parcial)
A nivel puramente técnico, replicar la funcionalidad base en una PWA es factible en un 80%:
* **Compatibilidad de Mapas:** El formato de mapas vectoriales `.pmtiles` y el motor `MapLibre` están diseñados para operar nativamente en la web mediante solicitudes HTTP Range.
* **Interfaz de Usuario (UI):** Es posible replicar la experiencia de usuario utilizando tecnologías web modernas o compilando el propio código fuente actual a WebAssembly (Flutter Web).
* **Fricción Cero de Publicación:** Se elimina la necesidad de pasar por el proceso burocrático y los filtros de revisión de la Google Play Store y la Apple App Store.

---

## 3. Riesgos Críticos de la Arquitectura PWA (No Recomendable)
Las siguientes limitaciones técnicas inhabilitan a las PWA como herramientas confiables para escenarios donde no existe internet, redes celulares ni suministro eléctrico:

### 3.1. Volatilidad de Almacenamiento (Evicción Silenciosa)
El mayor riesgo de la PWA radica en la persistencia de datos. AguaCION requiere almacenar permanentemente ~50 MB de datos locales (mapas de ciudad, grafos de enrutamiento y puntos de abastecimiento) en la memoria del dispositivo.
* **El Problema Web:** En navegadores móviles (especialmente Safari en iOS), si el dispositivo del usuario se queda sin espacio de almacenamiento, **el sistema operativo purgará automáticamente los cachés de las PWA (IndexedDB y Cache Storage) sin solicitar confirmación al usuario**.
* **Escenario de Falla:** Un ciudadano instala la PWA preventivamente. Meses después, ocurre un sismo grave sin conectividad a internet. Al intentar abrir la PWA para buscar agua, descubrirá que el mapa fue eliminado por el sistema operativo meses atrás para liberar espacio. 
* **Ventaja Nativa:** Las aplicaciones nativas empaquetadas (Instaladas por Play Store / App Store) tienen sus datos protegidos. El sistema operativo **nunca** borra los binarios de una app sin la intervención o confirmación explícita del usuario.

### 3.2. Acceso Frío al Hardware GNSS (GPS)
En un escenario de desastre (apagón de telecomunicaciones), el dispositivo debe triangular su posición utilizando exclusivamente los chips satelitales (Cold-Start GPS), sin ayuda de antenas celulares (A-GPS).
* **Limitación Web:** Las API de geolocalización de los navegadores web (`navigator.geolocation`) presentan severas limitaciones, lentitud o fallas totales cuando se intenta obtener coordenadas de alta precisión en ausencia total de red. Además, las PWA no pueden ejecutar servicios de geolocalización robustos en segundo plano.

### 3.3. Cuellos de Botella en Rendimiento Computacional
La aplicación realiza cálculos matemáticos intensivos (Algoritmo A*) sobre un grafo de calles convertido en un archivo binario masivo de 30 MB (`.bin`).
* **Limitación Web:** Procesar y recorrer matemáticamente archivos binarios tan pesados en el hilo principal (Main Thread) de un navegador móvil, especialmente en dispositivos de gama baja, puede ocasionar congelamientos de pantalla (OOM - Out of Memory) o forzar al navegador a recargar la pestaña abruptamente. El código AOT (Ahead-Of-Time) de una app nativa procesa estos algoritmos en fracciones de milisegundo sin afectar la batería.

---

## 4. Respuesta a la Fricción Comercial (Tiendas de Apps)
El argumento principal a favor de la PWA es evitar los "estrictos términos" de publicación de Google y Apple. Sin embargo, para este proyecto en particular, el proceso de revisión será extremadamente ágil y con mínimo riesgo de rechazo por las siguientes razones:

1. **Cero Privacidad Comprometida:** La aplicación es anónima. No solicita correo, no requiere crear cuentas de usuario ni procesa pagos.
2. **Cero Recolección de Datos:** La lectura del GPS del ciudadano ocurre estrictamente de manera local. Las coordenadas nunca abandonan el dispositivo, puesto que la app no se conecta a ninguna base de datos central ni API de monitoreo.
3. **Cero Dependencia de Terceros:** No se utilizan llaves comerciales (API Keys) de terceros que puedan violar términos de servicio por uso indebido.

Para los revisores de Apple y Google, AguaCION se clasifica como una **"Herramienta de Utilidad/Brújula Offline"**, siendo una de las categorías más sencillas de auditar y aprobar.

---

## 5. Conclusión General
La recomendación de la OTI es acertada y es el estándar de oro de la industria para el 90% de los portales gubernamentales orientados a consultas en línea, pagos y lectura de información.

Sin embargo, para el 10% restante de **Sistemas de Misión Crítica y Supervivencia (Disaster Response)**, la inmutabilidad de los datos y el acceso de bajo nivel al hardware del celular no son negociables. Por ello, **la arquitectura actual como Aplicación Móvil Nativa debe mantenerse** como la única garantía de que la herramienta estará funcional en el bolsillo del ciudadano en el momento que ocurra un desastre de gran magnitud.
