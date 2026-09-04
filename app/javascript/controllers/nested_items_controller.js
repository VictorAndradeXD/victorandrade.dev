import { Controller } from "@hotwired/stimulus"

// Detalhamento de um lançamento: adiciona/remove linhas e mostra, ao vivo,
// quanto do valor principal ainda está sem descrição. O limite real é
// validado no servidor e no banco — isto aqui é só feedback imediato.
export default class extends Controller {
  static targets = ["list", "template", "amount", "itemAmount", "remainder", "warning"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.recalculate()
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-item-row]")
    const destroyField = row.querySelector("input[name*='_destroy']")

    if (destroyField) {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }

    this.recalculate()
  }

  recalculate() {
    const total = this.#parse(this.amountTarget.value)
    const described = this.itemAmountTargets
      .filter((field) => !field.closest("[data-item-row]").hidden)
      .reduce((sum, field) => sum + this.#parse(field.value), 0)

    const remainder = total - described

    this.remainderTarget.textContent = this.#format(remainder)
    this.warningTarget.hidden = remainder >= 0
  }

  #parse(value) {
    const parsed = parseFloat(String(value).replace(",", "."))
    return Number.isFinite(parsed) ? parsed : 0
  }

  #format(value) {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
  }
}
