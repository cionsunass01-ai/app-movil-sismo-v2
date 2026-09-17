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

  const ICONS = {
    download: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0; display:block;">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
      <polyline points="7 10 12 15 17 10"></polyline>
      <line x1="12" y1="15" x2="12" y2="3"></line>
    </svg>`,
    check: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0; display:block;">
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
      <polyline points="22 4 12 14.01 9 11.01"></polyline>
    </svg>`,
    database: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0; display:block;">
      <ellipse cx="12" cy="5" rx="9" ry="3"></ellipse>
      <path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path>
      <path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path>
    </svg>`,
    alert: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0; display:block;">
      <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"></path>
      <line x1="12" y1="9" x2="12" y2="13"></line>
      <line x1="12" y1="17" x2="12.01" y2="17"></line>
    </svg>`
  };

  let onboardingCard = null;
  let autoHideTimeout = null;

  function showOnboardingProgress({ icon, title, subtitle, progress, showBar, barColor, autoHideMs }) {
    if (!onboardingCard) {
      onboardingCard = document.createElement('div');
      onboardingCard.id = 'aguacion-onboarding-precarga';
      onboardingCard.style.cssText = [
        'position: fixed',
        'bottom: 76px',
        'left: 50%',
        'transform: translateX(-50%) translateY(20px)',
        'width: calc(100% - 32px)',
        'max-width: 420px',
        'background: rgba(15, 23, 42, 0.95)',
        'border: 1px solid rgba(51, 65, 85, 0.85)',
        'border-radius: 14px',
        'padding: 12px 16px',
        'box-shadow: 0 12px 32px rgba(0, 0, 0, 0.35)',
        'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'color: #ffffff',
        'z-index: 99999',
        'pointer-events: none',
        'opacity: 0',
        'transition: opacity 0.3s cubic-bezier(0.16, 1, 0.3, 1), transform 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
        'backdrop-filter: blur(12px)',
        '-webkit-backdrop-filter: blur(12px)',
        'box-sizing: border-box'
      ].join(';');
      document.body.appendChild(onboardingCard);
    }

    if (autoHideTimeout) {
      clearTimeout(autoHideTimeout);
      autoHideTimeout = null;
    }

    const pct = Math.max(0, Math.min(100, Math.round(progress || 0)));
    const iconSvg = ICONS[icon] || ICONS.download;
    const progressFill = barColor || 'linear-gradient(90deg, #0284c7 0%, #38bdf8 100%)';

    onboardingCard.innerHTML = `
      <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px;">
        <div style="display: flex; align-items: center; gap: 12px; min-width: 0; flex: 1;">
          <div style="display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; border-radius: 10px; background: rgba(30, 41, 59, 0.85); border: 1px solid rgba(51, 65, 85, 0.6); flex-shrink: 0;">
            ${iconSvg}
          </div>
          <div style="display: flex; flex-direction: column; min-width: 0; flex: 1;">
            <div style="font-size: 12.5px; font-weight: 700; color: #f8fafc; letter-spacing: -0.01em; line-height: 1.3; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
              ${title}
            </div>
            <div style="font-size: 11px; font-weight: 500; color: #94a3b8; line-height: 1.3; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
              ${subtitle}
            </div>
          </div>
        </div>
        ${showBar ? `
          <div style="font-size: 13px; font-weight: 800; color: #38bdf8; font-variant-numeric: tabular-nums; flex-shrink: 0; letter-spacing: -0.02em;">
            ${pct}%
          </div>
        ` : ''}
      </div>
      ${showBar ? `
        <div style="margin-top: 10px; width: 100%; height: 5px; background: #334155; border-radius: 9999px; overflow: hidden;">
          <div style="width: ${pct}%; height: 100%; background: ${progressFill}; border-radius: 9999px; transition: width 0.2s ease-out;"></div>
        </div>
      ` : ''}
    `;

    requestAnimationFrame(() => {
      onboardingCard.style.opacity = '1';
      onboardingCard.style.transform = 'translateX(-50%) translateY(0)';
    });

    if (autoHideMs && autoHideMs > 0) {
      autoHideTimeout = setTimeout(() => {
        if (onboardingCard) {
          onboardingCard.style.opacity = '0';
          onboardingCard.style.transform = 'translateX(-50%) translateY(14px)';
        }
      }, autoHideMs);
    }
  }

  // Download PMTiles with progress tracking if online and not yet cached
  async function downloadAndCachePmtiles() {
    window.aguacionMapStatus.isLoading = true;
    window.dispatchEvent(new CustomEvent('aguacion_map_status_change', { detail: window.aguacionMapStatus }));
    showOnboardingProgress({
      icon: 'download',
      title: 'Precarga de Cartografía Offline',
      subtitle: 'Descargando mapa vectorial de Lima (10.6 MB)',
      progress: 0,
      showBar: true
    });

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
        showOnboardingProgress({
          icon: 'download',
          title: 'Precarga de Cartografía Offline',
          subtitle: 'Descargando mapa vectorial de Lima (10.6 MB)',
          progress: pct,
          showBar: true
        });
      }

      const blob = new Blob(chunks, { type: 'application/octet-stream' });
      await saveBlobToDb(PMTILES_KEY, blob);

      window.aguacionMapStatus.isReady = true;
      window.aguacionMapStatus.isLoading = false;
      window.aguacionMapStatus.progress = 100;
      window.aguacionMapStatus.source = 'network';

      console.log('[PMTiles Offline] PMTiles archive stored in IndexedDB (' + (blob.size / (1024 * 1024)).toFixed(1) + ' MB)');
      showOnboardingProgress({
        icon: 'check',
        title: 'Cartografía Offline Lista',
        subtitle: '10.6 MB almacenados para emergencias sin internet',
        progress: 100,
        showBar: true,
        barColor: '#10b981',
        autoHideMs: 3500
      });
      window.dispatchEvent(new CustomEvent('aguacion_map_ready', { detail: window.aguacionMapStatus }));
      return blob;
    } catch (err) {
      console.error('[PMTiles Offline] Download error:', err);
      window.aguacionMapStatus.isLoading = false;
      window.aguacionMapStatus.error = err.message;
      showOnboardingProgress({
        icon: 'alert',
        title: 'Precarga Pendiente',
        subtitle: 'Conéctate a internet para guardar el mapa de Lima',
        showBar: false,
        autoHideMs: 4000
      });
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
      showOnboardingProgress({
        icon: 'database',
        title: 'Cartografía Local Verificada',
        subtitle: 'Mapa vectorial activo en memoria del dispositivo',
        showBar: false,
        autoHideMs: 2200
      });
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
