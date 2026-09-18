/**
 * sw.js - Service Worker for AguaCION PWA
 * 
 * Provides offline-first caching for the application shell, Flutter assets,
 * fonts, styles, and map libraries.
 */

const CACHE_NAME = 'aguacion-pwa-v5';

const PRECACHE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'flutter_bootstrap.js',
  'main.dart.js',
  'maplibre-gl.js',
  'maplibre-gl.css',
  'pmtiles.js',
  'pmtiles_offline.js',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/poc/data/water_points_normalized.json',
  'assets/poc/styles/emergency_geometric_style.json',
  'assets/poc/fonts/Noto%20Sans%20Regular/0-255.pbf',
  'assets/poc/fonts/Noto%20Sans%20Regular/256-511.pbf',
  'assets/poc/fonts/Noto%20Sans%20Bold/0-255.pbf',
  'assets/poc/fonts/Noto%20Sans%20Bold/256-511.pbf',
  'assets/poc/fonts/Noto Sans Regular/0-255.pbf',
  'assets/poc/fonts/Noto Sans Regular/256-511.pbf',
  'assets/poc/fonts/Noto Sans Bold/0-255.pbf',
  'assets/poc/fonts/Noto Sans Bold/256-511.pbf'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Pre-caching AguaCION offline assets...');
      return Promise.allSettled(
        PRECACHE_ASSETS.map((url) =>
          fetch(url)
            .then((response) => {
              if (response.ok) {
                return cache.put(url, response).catch(() => {});
              }
            })
            .catch((err) => {
              console.warn('[SW] Pre-cache item failed:', url, err.message);
            })
        )
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[SW] Purging outdated cache:', key);
            return caches.delete(key);
          }
        })
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  // Skip non-GET requests or browser extension requests
  if (request.method !== 'GET' || url.protocol.startsWith('chrome-extension')) {
    return;
  }

  // Handle asset path duality between Flutter dev server (/assets/poc/) and release build (/assets/assets/poc/)
  if (url.pathname.includes('/assets/assets/poc/')) {
    const fallbackPath = url.pathname.replace('/assets/assets/poc/', '/assets/poc/');
    const fallbackUrl = new URL(fallbackPath, url.origin).toString();
    event.respondWith(
      caches.match(request, { ignoreSearch: true }).then((cached) => {
        if (cached) return cached;
        return fetch(request).then((res) => {
          if (res.ok) return res;
          return fetch(fallbackUrl);
        }).catch(() => fetch(fallbackUrl));
      })
    );
    return;
  }

  // PMTiles Range requests are handled in-memory by pmtiles_offline.js LocalBlobSource
  event.respondWith(
    caches.match(request, { ignoreSearch: true }).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(request).then((networkResponse) => {
        // Cache standard successful responses
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          // Do not cache the 10MB PMTiles file in Cache Storage because it is already in IndexedDB
          if (!url.pathname.endsWith('.pmtiles')) {
            try {
              const copy = networkResponse.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(request, copy).catch(() => {}));
            } catch (_) {}
          }
        }
        return networkResponse;
      }).catch((fetchErr) => {
        // Fallback for HTML navigations when completely offline
        if (request.mode === 'navigate') {
          return caches.match('index.html');
        }
        throw fetchErr;
      });
    })
  );
});
