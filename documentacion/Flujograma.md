# Flujogramas y Secuencia de Operación - AguaCION

El presente documento detalla la secuencia técnica y la experiencia de usuario (End-to-End) en la aplicación **AguaCION**, abarcando tanto el primer contacto del ciudadano con la plataforma como la respuesta inmediata durante una catástrofe sin internet ni energía eléctrica.

---

## 1. Flujograma General del Ciclo de Vida del Ciudadano

```mermaid
flowchart TD
    START([1. Inicio de la Aplicación]) --> DETECT{¿Primera vez en PWA\no falta mapa?}
    
    DETECT -- Sí (PWA Web) --> ONB_DL["Descarga Streaming de Cartografía\n(Barra de Progreso SVG: 0% a 100%)"]
    ONB_DL --> IDB_STORE["Guardado de PMTiles (10.6 MB)\nen IndexedDB Local"]
    IDB_STORE --> PERSIST["Solicitud de Cuota Persistente\nnavigator.storage.persist()"]
    PERSIST --> PROMPT_PWA{"¿Es navegador PWA\nno instalado?"}
    
    DETECT -- No (Ya en Caché o App Nativa) --> IDB_LOAD["Montaje de PMTiles desde Memoria\n(LocalBlobSource o mmap OS)"]
    IDB_LOAD --> PROMPT_PWA
    
    PROMPT_PWA -- Sí --> MOD_A2HS["Modal Asistido de Instalación\n(Agregar a Pantalla de Inicio)"]
    PROMPT_PWA -- No / Instalado --> DISCLAIMER["Despliegue de Aviso Institucional\n(Puntos sujetos a confirmación 48h)"]
    MOD_A2HS --> DISCLAIMER
    
    DISCLAIMER --> LOC_CHECK{"¿Tiene permiso\nde Ubicación?"}
    
    LOC_CHECK -- No --> MOD_PRIMER["Modal Educativo de Ubicación\n(Explica cálculo local sin subir datos)"]
    MOD_PRIMER --> REQ_GPS["Solicitud de GPS Nativo al OS"]
    REQ_GPS --> LOC_OK{"¿Permiso concedido?"}
    
    LOC_CHECK -- Sí --> GET_COORDS["Lectura de Coordenadas Satelitales\n(Sensor GNSS Cold-Start sin red)"]
    LOC_OK -- Sí --> GET_COORDS
    LOC_OK -- No --> FALLBACK_MAP["Centro Neutral (Plaza Mayor de Lima)\nSelección manual en el mapa"]
    
    GET_COORDS --> SNAPPING["Snapping Ortogonal a Red Vial\n(Spatial Grid 275m)"]
    FALLBACK_MAP --> MANUAL_SNAP["Snapping del Punto Seleccionado"]
    
    SNAPPING --> ADAPT_SEARCH["Búsqueda Adaptativa Geodésica\n(Poda de los 433 puntos oficiales)"]
    MANUAL_SNAP --> ADAPT_SEARCH
    
    ADAPT_SEARCH --> ASTAR["Ejecución Algoritmo A* Forward\n(Cálculo sobre Grafo Binario AGUACSR1)"]
    ASTAR --> RENDER_ROUTE["Visualización de Ruta Óptima a Pie\n(Polilínea, Distancia, Tiempo Estimado)"]
    
    RENDER_ROUTE --> OBSTACLE{"¿Encuentra calle bloqueada\npor escombros?"}
    OBSTACLE -- No --> REACH_POINT([Llegada al Punto de Abastecimiento])
    OBSTACLE -- Sí --> BLOCK_EDGE["Reportar Vía Bloqueada en UI\n(Bloqueo Dinámico de Arista en RAM)"]
    BLOCK_EDGE --> ASTAR
```

---

## 2. Diagrama de Secuencia: Arranque, Precarga y Renderizado Offline

Detalla la interacción entre la interfaz gráfica, los adaptadores de almacenamiento y el motor de teselas vectoriales:

```mermaid
sequenceDiagram
    autonumber
    actor U as Ciudadano
    participant UI as Flutter App (UI)
    participant ADAPT as pmtiles_offline.js
    participant IDB as IndexedDB (aguacion_offline_db)
    participant SW as Service Worker (sw.js)
    participant MAP as MapLibre GL / Native

    U->>UI: Abre la aplicación
    UI->>SW: Solicita App Shell, CanvasKit y glifos PBF
    SW-->>UI: Responde desde Cache-First (0 red)

    UI->>ADAPT: Inicializar protocolo 'pmtiles://'
    ADAPT->>IDB: Consultar clave 'lima_callao_pmtiles'
    
    alt Primera vez en línea (No existe en IndexedDB)
        ADAPT->>UI: Dispara evento 'aguacion_map_progress'
        UI->>U: Muestra Tarjeta Onboarding (Barra de progreso SVG 0%..100%)
        ADAPT->>ADAPT: Descarga binario en streaming (10.6 MB)
        ADAPT->>IDB: Almacena Blob completo en base de datos
        ADAPT->>UI: Dispara evento 'aguacion_map_ready'
        UI->>U: Barra verde (100%) y confirmación de Cartografía Lista
    else Ya almacenado previamente (Uso Offline / Modo Avión)
        IDB-->>ADAPT: Retorna Blob de 10.6 MB en memoria
        ADAPT->>UI: Dispara evento 'aguacion_map_ready'
        UI->>U: Breve confirmación: "Cartografía Local Verificada"
    end

    UI->>MAP: Inicializar MapLibreMap(styleString)
    MAP->>ADAPT: Solicita tesela vectorial (pmtiles://...)
    ADAPT->>ADAPT: LocalBlobSource.getBytes(offset, length)
    ADAPT-->>MAP: Retorna ArrayBuffer del tile (Sin llamada HTTP)
    MAP-->>U: Renderiza calles, costas, distritos y puntos de agua
```

---

## 3. Diagrama de Secuencia: Permiso Amigable de Ubicación (Location Primer)

Para evitar que el usuario bloquee el GPS ante la alerta fría del navegador, se implementa una secuencia pedagógica previa:

```mermaid
sequenceDiagram
    autonumber
    actor U as Ciudadano
    participant UI as Flutter App
    participant MOD as LocationPermissionModal
    participant OS as Sistema Operativo / Navegador

    UI->>UI: Verifica estado de permiso de geolocalización
    alt Permiso ya otorgado
        UI->>OS: Obtener posición actual GNSS
        OS-->>UI: Retorna [Lat, Lon]
    else Permiso No Otorgado / Primera vez
        UI->>MOD: Despliega LocationPermissionModal
        MOD-->>U: Explica pedagógicamente:
        Note over U,MOD: 1. "Para calcular la ruta más cercana a pie"<br/>2. "Tus datos nunca salen del teléfono"<br/>3. "Funciona sin internet mediante satélites"
        
        alt Ciudadano Acepta ("Permitir Ubicación")
            U->>MOD: Toca botón "Permitir Ubicación"
            MOD->>OS: Invoca API del sistema (Geolocator.requestPermission)
            OS-->>U: Diálogo nativo del sistema ("¿Permitir acceso a ubicación?")
            U->>OS: Concede permiso
            OS-->>UI: Retorna [Lat, Lon] de alta precisión
            UI->>UI: Centra mapa y calcula ruta al punto más cercano
        else Ciudadano Poscompone ("En otro momento")
            U->>MOD: Toca botón "En otro momento"
            MOD-->>UI: Cierra modal
            UI->>UI: Mantiene centro neutral (Plaza Mayor de Lima)
            UI->>U: Muestra banner superior para reactivar cuando desee
        end
    end
```

---

## 4. Diagrama de Secuencia: Ruteo A* Autónomo y Bloqueo Dinámico de Vías

Detalla el procesamiento matemático desconectado cuando el usuario se desplaza hacia un punto de suministro y se topa con escombros o vías intransitables:

```mermaid
sequenceDiagram
    autonumber
    actor U as Ciudadano
    participant UI as Pantalla del Mapa
    participant ROUTE as Motor Offline (OfflineRoutingEngine)
    participant CSR as Grafo Binario AGUACSR1
    participant MAP as MapLibre

    U->>UI: Solicita "Cómo llegar a pie"
    UI->>ROUTE: calculateRoute(origen, puntoDestino)
    
    ROUTE->>ROUTE: 1. Snapping ortogonal a la red vial (Spatial Grid 275m)
    ROUTE->>ROUTE: 2. Búsqueda adaptativa geodésica entre los 433 puntos
    ROUTE->>CSR: 3. Exploración de aristas y pesos en Int32List
    ROUTE->>ROUTE: 4. Ejecución de A* Forward monodireccional
    
    ROUTE-->>UI: Retorna RouteResult (Polilínea, 850m, 11 min)
    UI->>MAP: Dibuja línea de ruta sobre las calles
    MAP-->>U: Muestra trayecto a pie en el mapa

    opt Ciudadano encuentra calle colapsada por sismo
        U->>UI: Toca botón "Reportar vía bloqueada" en el mapa
        UI->>ROUTE: blockSegment(edgeId)
        Note over ROUTE,CSR: La arista queda inhabilitada<br/>en la memoria RAM de la sesión
        ROUTE->>ROUTE: Recálculo inmediato con A* (omitiendo vía dañada)
        ROUTE-->>UI: Retorna nueva RouteResult alternativa (+150m, desvío seguro)
        UI->>MAP: Actualiza trazo en pantalla en tiempo real
        MAP-->>U: Visualiza nuevo desvío peatonal seguro
    end
```
