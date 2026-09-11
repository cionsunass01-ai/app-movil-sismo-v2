# Implementación de Etiquetas Cartográficas Offline (Glyphs Locales y MapLibre)

**Proyecto:** Agua Segura Perú / AguaCION — SUNASS
**Hito:** Hito 2D — Hardening Cartográfico, Auditoría de Acceso y Validación Física
**Fecha:** 11 de septiembre de 2026
**Objetivo:** Habilitar la visualización de nombres de calles, avenidas, ríos y referencias distritales 100% offline dentro de MapLibre Flutter, sin dependencias de red (`http://`, `https://`) ni servidores locales de teselas.

---

## 1. Auditoría del Contenedor PMTiles Actual

Antes de descargar tipografías o modificar los estilos vectoriales, se realizó una inspección a bajo nivel del archivo binario [lima_callao_z14.pmtiles](assets/poc/maps/lima_callao_z14.pmtiles) (10.17 MB) utilizando la herramienta oficial `pmtiles` y decodificadores de protobuf MVT:

### Hallazgos de Capas y Atributos:
* **Capa `roads` (Vías Urbanas):**
  * Presenta atributos de denominación: `name`, `name:es`, `name:en`, `ref`, `shield_text`, `kind`, `kind_detail`, `is_bridge`, `is_tunnel`, `service`.
  * Verificación en tesela de alta resolución (z14/4686/8744, Centro Histórico de Lima):
    * Se identificaron más de **290 cadenas textuales de nombres viales** en una sola tesela, incluyendo:
      * *Vía de Evitamiento* (`PE-1N`)
      * *Avenida Paseo de la República* / *Vía Expresa Luis Fernán Bedoya Reyes*
      * *Vía Expresa Línea Amarilla*
      * *Avenida Abancay*
      * *Avenida Tacna*
      * *Avenida Nicolás de Piérola*
      * *Jirón de la Unión*
      * *Jirón Loreto*
      * *Puente Ricardo Palma*
* **Capa `places` (Lugares y Asentamientos):**
  * Presenta atributos: `name`, `name:es`, `kind` (`city`, `district`, `neighbourhood`, `suburb`, `locality`), `population`.
* **Capa `water` (Hidrografía):**
  * Presenta atributos: `name`, `name:es`, `kind` (`river`, `water`, `canal`), con nombres como *Río Rímac*.

### Dictamen de Auditoría:
$$\mathbf{STREET\_NAME\_ATTRIBUTES\_PRESENT = YES}$$

**Conclusión:** El archivo PMTiles actual contiene todos los atributos requeridos. No fue necesario regenerar las teselas ni alterar la cartografía base de OpenStreetMap. La ausencia previa de nombres en pantalla se debía exclusivamente a que el estilo minimalista preliminar carecía de capas `symbol` y de fuentes PBF locales.

---

## 2. Jerarquía y Selección de Etiquetas para Emergencias

En cumplimiento de los principios de diseño de AguaCION, el mapa de emergencia no debe saturarse con puntos de interés comerciales, tiendas, restaurantes o publicidad. Se priorizó estrictamente la **orientación espacial y la legibilidad**:

| Capa de Etiquetas | Fuente / Filtro | Rango de Zoom | Tipografía y Estilo | Propósito de Orientación |
| :--- | :--- | :---: | :--- | :--- |
| **`places_labels`** | `places` (`district`, `suburb`, `neighbourhood`, `locality`) | z10 a z16 | Noto Sans Bold (11 a 14 pt, mayúsculas, espaciado amplio, halo blanco) | Permite al usuario identificar en qué distrito o zona urbana se encuentra. |
| **`water_labels`** | `water` (`has name`) | z11 a z16 | Noto Sans Regular (11 pt, azul `#0284c7`, colocación lineal a lo largo del cauce) | Reconocimiento inmediato de barreras naturales (Río Rímac, canales). |
| **`roads_major_labels`** | `roads` (`kind` en `major_road`, `highway`) | z12 a z16 | Noto Sans Bold (10 a 12.5 pt, `#1e293b`, halo blanco de 1.5 pt, placement lineal) | Visualización clara de autopistas, avenidas troncales y puentes de conexión. |
| **`roads_minor_labels`** | `roads` (`has name`, secundarias, jirones, pasajes) | z13.5 a z16 | Noto Sans Regular (9.5 a 11 pt, `#334155`, halo blanco de 1.2 pt, placement lineal) | Distinción de jirones y calles locales al aproximarse al punto de agua. |

---

## 3. Arquitectura de Glifos (Glyphs) 100% Locales

### Limitación Oficial de MapLibre Native:
De acuerdo con la documentación y changelog oficial de MapLibre Flutter (`maplibre_gl` 0.27.1, issue #338):
> *"A style loaded from Flutter assets cannot point sprite and glyphs at asset://, because the native C++ engines fetch those themselves; copy the files to disk at startup and reference them with file://"*

### Solución Implementada:
1. **Empaquetado en Assets de Flutter:** Los archivos binarios de glifos en formato Protocol Buffer (`.pbf`) se incluyen en el bundle de la aplicación en:
   * `assets/poc/fonts/Noto Sans Regular/0-255.pbf` (76.5 KB)
   * `assets/poc/fonts/Noto Sans Regular/256-511.pbf` (127.2 KB)
   * `assets/poc/fonts/Noto Sans Bold/0-255.pbf` (81.1 KB)
   * `assets/poc/fonts/Noto Sans Bold/256-511.pbf` (134.5 KB)
2. **Desempaquetado en Inicialización (`PmtilesManager.prepareLocalFonts()`):**
   Durante el arranque de la vista del POC, estos archivos se escriben en el almacenamiento privado de la aplicación (`getApplicationDocumentsDirectory()/fonts/`).
3. **Compatibilidad con Decodificación de URL en Motores C++:**
   Para evitar fallos de resolución entre motores que esperan la ruta con espacios (`Noto Sans Regular`) vs. motores que esperan codificación de porcentaje (`Noto%20Sans%20Regular`), el gestor crea en disco ambas carpetas aliadas de forma transparente.
4. **Inyección Dinámica de URI `file://`:**
   El JSON de estilo sustituye en caliente la propiedad `"glyphs"`:
   ```json
   "glyphs": "file:///data/user/0/pe.gob.sunass.aguacion_app/app_flutter/fonts/{fontstack}/{range}.pbf"
   ```
   (en Android) o:
   ```json
   "glyphs": "file:///var/mobile/Containers/Data/Application/.../Documents/fonts/{fontstack}/{range}.pbf"
   ```
   (en iOS).
5. **Cero Servidor Local:**
   $$\mathbf{LOCAL\_LOOPBACK\_SERVER\_USED = NO}$$
   Tanto las teselas vectoriales PMTiles como los glifos PBF se leen directamente desde el sistema de archivos nativo sin abrir puertos TCP `127.0.0.1`.

---

## 4. Proveniencia y Licencia de la Tipografía

* **Nombre de la Familia Tipográfica:** Noto Sans (Variantes: *Regular* y *Bold*).
* **Diseñador / Proveedor:** Google Fonts / MapLibre Foundation.
* **Licencia Oficial:** **SIL Open Font License (OFL) Version 1.1**.
* **Condiciones de Uso:**
  Permite libre distribución, copia, inclusión, empaquetado y uso comercial o no comercial dentro de cualquier software o sistema gubernamental/institucional.
* **Verificación de Cobertura de Caracteres en Español:**
  El rango base `0-255.pbf` (Basic Latin + Latin-1 Supplement) fue auditado a nivel de bytecode de protobuf, verificando la presencia física de todos los glifos indispensables para la toponimia peruana:
  * `ñ` (U+00F1) y `Ñ` (U+00D1): **VERIFICADO (FOUND)**
  * `á`, `é`, `í`, `ó`, `ú`, `Á`, `É`, `Í`, `Ó`, `Ú`: **VERIFICADO (FOUND)**
  * `ü`, `Ü`: **VERIFICADO (FOUND)**
  * `¿`, `¡`: **VERIFICADO (FOUND)**
  * Dígitos `0-9`, signos de puntuación y símbolos viales: **VERIFICADO (FOUND)**
  * Rango extendido `256-511.pbf`: Cobertura completa de Latin Extended-A.

---

## 5. Auditoría de Cero Dependencias de Red en Style JSON

Se ejecutó un escaneo automatizado en el archivo de estilo [`emergency_geometric_style.json`](assets/poc/styles/emergency_geometric_style.json):
* Peticiones `http://`: **0**
* Peticiones `https://`: **0**
* Recursos de teselas: Exclusivamente `pmtiles://file://...`
* Recursos de tipografía: Exclusivamente `file://.../{fontstack}/{range}.pbf`
* Sprites / Iconos externos: Omitidos conscientemente (se emplean capas vectoriales nativas).

---

## 6. Verificación en Suite de Pruebas Automatizadas

Se incorporó la prueba unitaria automatizada `Test 8` en [`test/poc/offline_navigation_test.dart`](test/poc/offline_navigation_test.dart):
* Comprueba la validez del JSON de estilo.
* Verifica la ausencia de URLs remotas.
* Valida la existencia de las 4 capas de símbolos viales y de lugares.
* Confirma la presencia física e integridad de los 4 archivos de glifos en los assets.
* **Resultado:** `15/15 tests passed` (`100% PASS`).
