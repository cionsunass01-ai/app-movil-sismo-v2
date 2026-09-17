# Documento de Contexto y Solicitud Tecnológica para Proveedor de Mapas (Ej. Google Maps)

**Fecha:** [Fecha actual]  
**De:** Equipo de Desarrollo - Proyecto AguaCION (Marco GRD - SUNASS)  
**Para:** Equipo Comercial y de Soluciones Técnicas de [Google Maps Platform / Proveedor]  
**Asunto:** Solicitud de Factibilidad Técnica y Licenciamiento para Caso de Uso Offline en Gestión de Riesgo de Desastres.

---

## 1. Resumen Ejecutivo
El presente documento tiene como propósito presentar el contexto técnico y operativo del proyecto **AguaCION**, una aplicación móvil desarrollada para la **Gestión del Riesgo de Desastres (GRD)** en el Perú. 
Buscamos explorar la viabilidad de utilizar los servicios cartográficos de su plataforma bajo un modelo de licenciamiento y operación predominantemente **offline**, debido a la naturaleza crítica de nuestra aplicación.

## 2. Contexto de la Aplicación (AguaCION)
Ante la inminencia de un sismo de gran magnitud (ej. en la costa central del Perú - Lima y Callao), se proyecta una caída masiva y prolongada de las telecomunicaciones e infraestructura de internet. En este escenario, la prioridad del Estado es asegurar el acceso a agua potable para la población afectada.

**AguaCION** es un aplicativo móvil que permite a los ciudadanos:
1. Conocer los puntos de abastecimiento de agua activos más cercanos.
2. Navegar peatonalmente hacia dichos puntos utilizando un motor de búsqueda y ruteo ejecutado 100% en el dispositivo móvil.
3. Operar con **cero conectividad a internet (0 bytes)** durante el evento adverso.

## 3. Estado Actual de la Arquitectura Técnica
Actualmente, el proyecto ha validado los siguientes hitos técnicos mediante pruebas de concepto:
*   **Mapas Vectoriales Offline:** Renderizado cartográfico local usando teselas vectoriales (PMTiles).
*   **Ruteo Peatonal en Dispositivo:** Uso de un Grafo Peatonal Offline comprimido (CSR) y algoritmo A* con heurística espacial.
*   **Adquisición GNSS:** Geolocalización por hardware (GPS satelital).
*   **Tamaño de la Huella de Datos:** Un paquete que abarca Lima y Callao (~10 MB en vectores y ~30 MB en el grafo de ruteo).

## 4. Requerimientos Hacia el Proveedor (Necesidades Específicas)
Dada la política estándar de las plataformas como Google Maps Platform (que a menudo restringe el caching prolongado o el uso desconectado masivo de sus teselas y rutas), deseamos plantear las siguientes consultas de factibilidad para una posible integración:

### 4.1. Licenciamiento para Almacenamiento Offline Prolongado
Requerimos autorización (Términos de Servicio Especiales o Enterprise) para pre-descargar de manera preventiva la data cartográfica de una región entera (Lima Metropolitana y el Callao) en los dispositivos de los ciudadanos. La data residirá en el dispositivo a la espera de un desastre y se actualizará periódicamente (ej. una vez al mes) cuando haya internet disponible.

### 4.2. Exportación de Datos Geométricos para Ruteo Local
Dado que el cálculo de rutas se realizará sin internet en el momento de la emergencia, ¿existe algún programa, API o servicio (ej. Mobility o un licenciamiento gubernamental de datos) que nos permita extraer un subconjunto del grafo vial (sólo peatonal) para empaquetarlo y consultarlo de forma local?

### 4.3. Programas de Ayuda Humanitaria y Respuesta a Crisis
El proyecto AguaCION se inscribe dentro de las estrategias de resiliencia del Estado Peruano (SUNASS / GRD). ¿Cuenta su plataforma con un programa de "Crisis Response", licenciamiento solidario o flexibilidad en las políticas de uso de APIs para este tipo de iniciativas de protección civil?

## 5. Volumetría y Operación Estimada
*   **Público Objetivo:** Ciudadanos de Lima y Callao.
*   **Uso regular (Conectado):** Únicamente durante la sincronización preventiva de datos (estimado 1 vez al mes por dispositivo).
*   **Uso crítico (Desconectado):** Picos masivos de uso durante los primeros 10 días tras un evento sísmico mayor. Todo el procesamiento (renderizado y ruteo) se da a nivel de CPU local, sin peticiones al servidor del proveedor durante la crisis.

## 6. Próximos Pasos Solicitados
Solicitamos agendar una reunión técnica/comercial para discutir:
1. Excepciones de ToS (Terms of Service) para almacenamiento offline en casos de desastre.
2. Alternativas técnicas que ofrecen (ej. Google Maps SDK for Android/iOS offline capabilities).
3. Estructura de costos o convenios gubernamentales.

---
**Atentamente,**
Equipo de Desarrollo AguaCION
*(Enlace a repositorio/Contacto de la Institución)*
