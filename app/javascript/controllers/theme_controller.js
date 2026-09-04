import { Controller } from "@hotwired/stimulus"

// Alterna claro/escuro. O escuro é o padrão: só o claro grava data-theme.
// A aplicação inicial acontece num script inline no <head> (ver o layout),
// senão a página pisca escura antes do JavaScript carregar.
export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.render()
  }

  toggle() {
    const isLight = document.documentElement.dataset.theme === "light"

    if (isLight) {
      delete document.documentElement.dataset.theme
      localStorage.removeItem("theme")
    } else {
      document.documentElement.dataset.theme = "light"
      try { localStorage.setItem("theme", "light") } catch {}
    }

    this.render()
  }

  render() {
    const isLight = document.documentElement.dataset.theme === "light"
    if (this.hasIconTarget) this.iconTarget.textContent = isLight ? "☾" : "☀"
    this.element.title = isLight ? "Mudar para o modo escuro" : "Mudar para o modo claro"
  }
}
