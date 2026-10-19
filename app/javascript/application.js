// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Registra o service worker só onde há manifest, isto é, nas telas do app.
// Ele não guarda dados em cache: serve para o Android aceitar a instalação e
// mostrar uma página de "sem conexão" no lugar do erro do navegador.
if ("serviceWorker" in navigator && document.querySelector('link[rel="manifest"]')) {
  navigator.serviceWorker.register("/service-worker.js")
}
