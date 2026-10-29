import { Controller } from "@hotwired/stimulus"

// Sliders das metas: atualiza ao vivo o total, o donut, os valores em reais e
// o aviso de estouro, e trava o Salvar enquanto a soma passar de 100%. A
// mesma regra é validada no servidor (BudgetGoalSet) — isto é só feedback.
export default class extends Controller {
  static targets = ["slider", "percent", "amount", "segment", "total",
                    "excessAlert", "excess", "remainingNote", "remaining", "submit"]
  static values = { income: Number, defaults: Object }

  connect() {
    this.refresh()
  }

  reset() {
    this.sliderTargets.forEach((slider) => {
      slider.value = this.defaultsValue[slider.dataset.key] ?? 0
    })
    this.refresh()
  }

  refresh() {
    const percents = Object.fromEntries(
      this.sliderTargets.map((slider) => [slider.dataset.key, parseInt(slider.value, 10) || 0])
    )
    const total = Object.values(percents).reduce((sum, value) => sum + value, 0)

    this.percentTargets.forEach((el) => { el.textContent = `${percents[el.dataset.key]}%` })
    this.amountTargets.forEach((el) => {
      el.textContent = this.#money(this.incomeValue * percents[el.dataset.key] / 100)
    })

    this.totalTarget.textContent = `${total}%`
    this.totalTarget.classList.toggle("text-expense", total > 100)

    this.excessTarget.textContent = Math.max(total - 100, 0)
    this.excessAlertTarget.hidden = total <= 100
    this.remainingTarget.textContent = Math.max(100 - total, 0)
    this.remainingNoteTarget.hidden = total >= 100
    this.submitTarget.disabled = total > 100

    this.#drawDonut(percents, Math.max(total, 100))
  }

  // Mesma conta do budgets/_donut: cada arco é um traço tracejado deslocado
  // pela soma dos anteriores.
  #drawDonut(percents, denominator) {
    const circumference = parseFloat(this.element.querySelector("[data-budget-goals-circumference]")
      .dataset.budgetGoalsCircumference)
    let offset = 0

    this.segmentTargets.forEach((circle) => {
      const length = (percents[circle.dataset.key] / denominator) * circumference
      circle.setAttribute("stroke-dasharray", `${length} ${circumference - length}`)
      circle.setAttribute("stroke-dashoffset", -offset)
      offset += length
    })
  }

  #money(value) {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
  }
}
