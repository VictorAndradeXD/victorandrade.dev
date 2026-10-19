// Service worker do app instalado no celular.
//
// Só a página offline vai para o cache. As telas do app nunca: são finanças
// de alguém, e quem abrir o app sem internet num celular emprestado não deve
// ver o extrato que ficou guardado. Sem rede, toda navegação cai na mesma
// página avisando que falta conexão.
//
// Ao mudar offline.html, troque a versão do CACHE para os celulares baixarem
// a nova.
const CACHE = "denfis-offline-v2"
const OFFLINE_URL = "/offline.html"

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.add(OFFLINE_URL)))
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

// Requisições que não são navegação (CSS, JS, Turbo) seguem direto para a
// rede, sem passar por aqui.
self.addEventListener("fetch", (event) => {
  if (event.request.mode !== "navigate") return

  event.respondWith(fetch(event.request).catch(() => caches.match(OFFLINE_URL)))
})
