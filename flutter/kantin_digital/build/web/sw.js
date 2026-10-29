// Service Worker untuk Kantin Digital PWA
// Mode network pass-through agar update file web Flutter tidak tertahan cache
const CACHE_NAME = 'kantin-pwa-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  // Pass-through langsung ke network agar aset selalu up to date
  event.respondWith(
    fetch(event.request).catch(() => {
      return fetch(event.request);
    })
  );
});
