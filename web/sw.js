// Lakshya Residency PWA Service Worker
const CACHE_NAME = 'lakshya-pwa-v1';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/apple-touch-icon.png',
  './icons/apple-touch-icon-180x180.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png'
];

// Install event - precache core shell assets
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    }).catch((err) => {
      console.warn('Pre-caching issue:', err);
    })
  );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((name) => {
          if (name !== CACHE_NAME && name.startsWith('lakshya-pwa-')) {
            console.log('Removing old cache:', name);
            return caches.delete(name);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - Network first with fallback to cache for HTML, cache first for static icons/assets
self.addEventListener('fetch', (event) => {
  const request = event.request;
  
  // Skip non-GET requests or browser extension/cross-origin requests
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  // For static icons and images, serve from cache then network
  if (url.origin === location.origin && (url.pathname.includes('/icons/') || url.pathname.endsWith('.png') || url.pathname.endsWith('.jpg'))) {
    event.respondWith(
      caches.match(request).then((cachedResponse) => {
        if (cachedResponse) return cachedResponse;
        return fetch(request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, responseClone));
          }
          return networkResponse;
        });
      })
    );
    return;
  }

  // Network first for other assets
  event.respondWith(
    fetch(request).catch(() => {
      return caches.match(request).then((response) => {
        if (response) return response;
        if (request.mode === 'navigate') {
          return caches.match('./index.html');
        }
      });
    })
  );
});
