// service worker بسيط — يخلّي التطبيق قابل للتثبيت ويشتغل بسرعة
// network-first: نجيب أحدث نسخة من الشبكة، ونرجع للكاش فقط لو ما في نت
const CACHE = "coach-app-v1";
const SHELL = ["./", "./index.html", "./config.js", "./manifest.webmanifest",
  "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((keys) =>
    Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", (e) => {
  const url = e.request.url;
  // لا تتدخّل في طلبات Supabase أو يوتيوب — خلّيها تروح للشبكة مباشرة
  if (url.includes("supabase.co") || url.includes("youtube") || url.includes("ytimg")) return;
  e.respondWith(
    fetch(e.request).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match(e.request).then((r) => r || caches.match("./index.html")))
  );
});
