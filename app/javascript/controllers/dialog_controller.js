import { Controller } from "@hotwired/stimulus"

// Abre o <dialog> assim que ele chega no turbo-frame e se remove do DOM ao
// fechar. Sem isso o conteúdo antigo ficaria no frame, e reabrir o mesmo dia
// não dispararia connect() de novo.
export default class extends Controller {
  connect() {
    if (!this.element.open) this.element.showModal()
  }

  close() {
    this.element.close()
  }

  // Clique no backdrop: o alvo é o próprio <dialog>, não o conteúdo interno.
  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  // Dispara no close() e também no Esc, que o <dialog> trata sozinho.
  teardown() {
    this.element.remove()
  }
}
