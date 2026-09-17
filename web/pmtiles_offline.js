/**
 * pmtiles_offline.js
 * 
 * High-performance Offline Adapter for PMTiles & MapLibre in AguaCION PWA.
 * 
 * 1. Automatically persists the 10.6MB PMTiles map file into IndexedDB.
 * 2. Uses navigator.storage.persist() to prevent iOS Safari & Android eviction.
 * 3. Provides a LocalBlobSource that slices bytes directly in-memory/disk with ZERO HTTP requests.
 * 4. Intercepts MapLibre's "pmtiles" protocol to eliminate 206 Partial Content network errors in Airplane Mode.
 */

(function () {
  'use strict';

  const DB_NAME = 'aguacion_offline_db';
  const DB_VERSION = 1;
  const STORE_NAME = 'blobs';
  const PMTILES_KEY = 'lima_callao_pmtiles';
  const ASSET_PMTILES_REL_PATH = 'assets/assets/poc/maps/lima_callao_z14.pmtiles';

  window.aguacionMapStatus = {
    isReady: false,
    isLoading: false,
    progress: 0,
    source: 'none', // 'indexeddb' | 'network' | 'none'
    error: null,
  };

  let dbInstance = null;

  function openDatabase() {
    if (dbInstance) return Promise.resolve(dbInstance);
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = (e) => {
        const db = e.target.result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME);
        }
      };
      request.onsuccess = () => {
        dbInstance = request.result;
        resolve(dbInstance);
      };
      request.onerror = () => reject(request.error);
    });
  }

  async function getBlobFromDb(key) {
    try {
      const db = await openDatabase();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readonly');
        const store = tx.objectStore(STORE_NAME);
        const req = store.get(key);
        req.onsuccess = () => resolve(req.result || null);
        req.onerror = () => reject(req.error);
      });
    } catch (e) {
      console.warn('[PMTiles Offline] Error accessing IndexedDB:', e);
      return null;
    }
  }

  async function saveBlobToDb(key, blob) {
    try {
      const db = await openDatabase();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const req = store.put(blob, key);
        req.onsuccess = () => resolve();
        req.onerror = () => reject(req.error);
      });
    } catch (e) {
      console.warn('[PMTiles Offline] Error saving blob to IndexedDB:', e);
    }
  }

  // Request durable storage persistence on mobile devices
  if (navigator.storage && navigator.storage.persist) {
    navigator.storage.persist().then((persistent) => {
      console.log('[PMTiles Offline] navigator.storage.persist granted:', persistent);
    }).catch(console.warn);
  }

  /**
   * LocalBlobSource
   * Implements the PMTiles Source interface using an in-memory or IndexedDB Blob.
   * Performs local slice() with ZERO HTTP requests.
   */
  class LocalBlobSource {
    constructor(blob, key) {
      this.blob = blob;
      this.key = key || 'lima_callao';
    }
    getKey() {
      return this.key;
    }
    async getBytes(offset, length) {
      const slice = this.blob.slice(offset, offset + length);
      const arrayBuffer = await slice.arrayBuffer();
      return { data: arrayBuffer };
    }
  }

  let resolveInstance;
  let rejectInstance;
  window.aguacionPmtilesInstancePromise = new Promise((resolve, reject) => {
    resolveInstance = resolve;
    rejectInstance = reject;
  });

  let toastElement = null;
  function updateStatusToast(htmlContent, autoHide) {
    if (!toastElement) {
      toastElement = document.createElement('div');
      toastElement.id = 'aguacion-offline-pill';
      toastElement.style.cssText = [
        'position: fixed',
        'bottom: 74px',
        'left: 50%',
        'transform: translateX(-50%)',
        'background: rgba(15, 23, 42, 0.92)',
        'color: #ffffff',
        'padding: 7px 16px',
        'border-radius: 24px',
        'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        'font-size: 11.5px',
        'font-weight: 600',
        'box-shadow: 0 4px 14px rgba(0,0,0,0.22)',
        'z-index: 99999',
        'pointer-events: none',
        'transition: opacity 0.35s ease, transform 0.35s ease',
        'display: flex',
        'align-items: center',
        'gap: 8px',
        'backdrop-filter: blur(8px)',
        '-webkit-backdrop-filter: blur(8px)'
      ].join(';');
      document.body.appendChild(toastElement);
    }
    toastElement.innerHTML = htmlContent;
    toastElement.style.opacity = '1';
    toastElement.style.transform = 'translateX(-50%) translateY(0)';

    if (autoHide) {
      setTimeout(() => {
        if (toastElement) {
          toastElement.style.opacity = '0';
          toastElement.style.transform = 'translateX(-50%) translateY(10px)';
        }
      }, 3500);
    }
  }

  // Download PMTiles with progress tracking if online and not yet cached
  async function downloadAndCachePmtiles() {
    window.aguacionMapStatus.isLoading = true;
    window.dispatchEvent(new CustomEvent('aguacion_map_status_change', { detail: window.aguacionMapStatus }));
    updateStatusToast('📥 Guardando mapa offline de Lima (10.6 MB)... 0%', false);

    try {
      const fullUrl = new URL(ASSET_PMTILES_REL_PATH, document.baseURI).toString();
      console.log('[PMTiles Offline] Fetching full PMTiles binary from:', fullUrl);

      const response = await fetch(fullUrl);
      if (!response.ok) {
        throw new Error('HTTP ' + response.status + ' fetching ' + fullUrl);
      }

      const contentLength = response.headers.get('content-length');
      const totalBytes = contentLength ? parseInt(contentLength, 10) : 10666090;

      let loadedBytes = 0;
      const reader = response.body.getReader();
      const chunks = [];

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        loadedBytes += value.byteLength;
        const pct = Math.min(100, Math.round((loadedBytes / totalBytes) * 100));
        window.aguacionMapStatus.progress = pct;
        window.dispatchEvent(new CustomEvent('aguacion_map_progress', { detail: window.aguacionMapStatus }));
        updateStatusToast('📥 Guardando mapa offline de Lima: ' + pct + '%', false);
      }

      const blob = new Blob(chunks, { type: 'application/octet-stream' });
      await saveBlobToDb(PMTILES_KEY, blob);

      window.aguacionMapStatus.isReady = true;
      window.aguacionMapStatus.isLoading = false;
      window.aguacionMapStatus.progress = 100;
      window.aguacionMapStatus.source = 'network';

      console.log('[PMTiles Offline] PMTiles archive stored in IndexedDB (' + (blob.size / (1024 * 1024)).toFixed(1) + ' MB)');
      updateStatusToast('✅ Mapa guardado: 100% listo para emergencias sin internet', true);
      window.dispatchEvent(new CustomEvent('aguacion_map_ready', { detail: window.aguacionMapStatus }));
      return blob;
    } catch (err) {
      console.error('[PMTiles Offline] Download error:', err);
      window.aguacionMapStatus.isLoading = false;
      window.aguacionMapStatus.error = err.message;
      updateStatusToast('⚠️ No se pudo guardar el mapa offline', true);
      window.dispatchEvent(new CustomEvent('aguacion_map_error', { detail: window.aguacionMapStatus }));
      throw err;
    }
  }

  // Initialize Map Data on load
  async function initOfflineMap() {
    let blob = await getBlobFromDb(PMTILES_KEY);
    if (blob && blob.size > 1000000) {
      console.log('[PMTiles Offline] Map loaded directly from IndexedDB (' + (blob.size / (1024 * 1024)).toFixed(1) + ' MB). 100% Offline Ready.');
      window.aguacionMapStatus.isReady = true;
      window.aguacionMapStatus.isLoading = false;
      window.aguacionMapStatus.progress = 100;
      window.aguacionMapStatus.source = 'indexeddb';
      updateStatusToast('🟢 Mapa offline listo en dispositivo', true);
      window.dispatchEvent(new CustomEvent('aguacion_map_ready', { detail: window.aguacionMapStatus }));
    } else {
      if (navigator.onLine) {
        try {
          blob = await downloadAndCachePmtiles();
        } catch (e) {
          console.warn('[PMTiles Offline] Network fetch failed, map may not load offline until first full sync:', e);
          rejectInstance(e);
          return;
        }
      } else {
        console.warn('[PMTiles Offline] Device is offline and map is not in IndexedDB cache yet.');
        rejectInstance(new Error('Device is offline and map is not cached.'));
        return;
      }
    }

    if (window.pmtiles && blob) {
      const blobSource = new LocalBlobSource(blob, 'lima_callao');
      const pmtilesInstance = new window.pmtiles.PMTiles(blobSource);
      window.aguacionOfflinePmtilesInstance = pmtilesInstance;
      resolveInstance(pmtilesInstance);
    }
  }

  // Register protocol with MapLibre
  function registerProtocol() {
    if (!window.maplibregl || !window.pmtiles) {
      setTimeout(registerProtocol, 50);
      return;
    }

    const protocol = new window.pmtiles.Protocol();
    const originalTile = protocol.tile.bind(protocol);

    protocol.tile = function (params, callback) {
      if (params.url && params.url.includes('lima_callao')) {
        window.aguacionPmtilesInstancePromise.then((instance) => {
          let pmtiles_url;
          if (params.type === 'json') {
            pmtiles_url = params.url.substr(10);
          } else {
            const re = new RegExp(/pmtiles:\/\/(.+)\/(\d+)\/(\d+)\/(\d+)/);
            const match = params.url.match(re);
            if (match) pmtiles_url = match[1];
          }

          if (pmtiles_url) {
            protocol.tiles.set(pmtiles_url, instance);
          }
          // Register all variations
          protocol.tiles.set('assets/assets/poc/maps/lima_callao_z14.pmtiles', instance);
          protocol.tiles.set('assets/poc/maps/lima_callao_z14.pmtiles', instance);
          protocol.tiles.set('lima_callao', instance);

          return originalTile(params, callback);
        }).catch((err) => {
          console.error('[PMTiles Offline] Tile error:', err);
          return originalTile(params, callback);
        });

        return { cancel: () => {} };
      }

      return originalTile(params, callback);
    };

    window.maplibregl.addProtocol('pmtiles', protocol.tile);
    console.log('[PMTiles Offline] MapLibre "pmtiles" protocol successfully hooked with offline IndexedDB adapter.');
  }

  // Initialize
  initOfflineMap();
  registerProtocol();
})();
