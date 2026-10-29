module BudgetsHelper
  # Ícones das seis metas, desenhados à mão no mesmo grid 24×24 e traço dos
  # Heroicons do ApplicationHelper, para os dois conjuntos conviverem.
  CATEGORY_ICON_PATHS = {
    "fixed_costs" => [ "M3 11.25 12 3.75l9 7.5", "M5.25 9.75V20.25h13.5V9.75", "M10 20.25v-5.5h4v5.5" ],
    "comfort" => [
      "M5.25 11.25 6.9 6.6a1.5 1.5 0 0 1 1.41-1h7.38a1.5 1.5 0 0 1 1.41 1l1.65 4.65",
      "M3.75 12.75a1.5 1.5 0 0 1 1.5-1.5h13.5a1.5 1.5 0 0 1 1.5 1.5v3.75h-16.5Z",
      "M6.75 16.5v2.25M17.25 16.5v2.25", "M7.5 13.875h.01M16.5 13.875h.01"
    ],
    "goals" => [
      "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Z", "M12 7.5a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9Z",
      "M12 11.25a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Z"
    ],
    "pleasures" => [ "M7.5 3.75h9V8.25a4.5 4.5 0 0 1-9 0Z", "M12 12.75v7.5", "M8.25 20.25h7.5" ],
    "financial_freedom" => [
      "M12 3.75v16.5",
      "M16.125 7.875c-.75-1.125-2.25-1.875-4.125-1.875-2.4 0-4.125 1.2-4.125 2.875S9.6 11.4 12 11.85s4.125 1.4 4.125 3.15S14.4 18 12 18c-1.875 0-3.375-.75-4.125-1.875"
    ],
    "knowledge" => [
      "M2.25 9.375 12 4.5l9.75 4.875L12 14.25Z", "M6.375 11.4v4.35c0 1.45 2.5 3 5.625 3s5.625-1.55 5.625-3V11.4",
      "M21.75 9.375v5.25"
    ]
  }.freeze

  def budget_icon(key, css: "w-4 h-4")
    paths = CATEGORY_ICON_PATHS.fetch(key)
      .map { |d| %(<path stroke-linecap="round" stroke-linejoin="round" d="#{d}"/>) }
      .join

    attrs = %(class="#{css}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true")
    "<svg #{attrs}>#{paths}</svg>".html_safe
  end

  # Quanto do previsto já foi: verde com folga, âmbar perto do limite,
  # vermelho estourado. O âmbar é o mesmo do fator R no módulo contábil.
  def budget_used_color(used)
    return "text-muted" if used.nil?
    return "text-expense" if used > 1
    return "text-amber-400" if used >= BigDecimal("0.85")

    "text-income"
  end

  def budget_ratio(ratio) = ratio.nil? ? "—" : percent(ratio, precision: 1)
end
