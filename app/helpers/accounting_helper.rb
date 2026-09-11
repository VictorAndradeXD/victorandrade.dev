module AccountingHelper
  # "28,00%" a partir de 0.28.
  def percent(value, precision: 2)
    number_to_percentage(value.to_d * 100, delimiter: ".", separator: ",", precision: precision)
  end

  # "Setembro/2026" — o mês por extenso, capitalizado.
  def month_label(date) = "#{I18n.t('date.month_names')[date.month]}/#{date.year}"

  # Como o fator R de uma janela deve ser apresentado.
  #
  # A margem de 2 pontos existe porque o fator R é degrau: quem está em 28,5%
  # cai para o anexo caro com um mês de faturamento acima da média, e descobrir
  # isso depois custa a diferença de alíquota do período inteiro.
  NEAR_EDGE = BigDecimal("0.02")

  def fator_r_status(window)
    fator = window.fator_r

    if !fator.reaches?
      { tone: :danger,  label: "Anexo V", note: "Fora do fator R" }
    elsif fator.value - Tax::FatorR::THRESHOLD <= NEAR_EDGE
      { tone: :warning, label: "Anexo III", note: "No limite" }
    else
      { tone: :good,    label: "Anexo III", note: "Folgado" }
    end
  end

  TONE_CLASSES = {
    danger:  "text-expense bg-expense/10 border-expense/25",
    warning: "text-amber-400 bg-amber-400/10 border-amber-400/25",
    good:    "text-income bg-income/10 border-income/25"
  }.freeze

  def tone_classes(tone) = TONE_CLASSES.fetch(tone)

  # Barra de progresso rumo aos 28%. Passa de 100% quando a empresa já está
  # acima do limite, então trava em 100 para a barra não vazar do trilho.
  def fator_r_progress(window)
    return 0 if window.rbt12.zero?

    [ (window.fator_r.value / Tax::FatorR::THRESHOLD * 100).to_f.round(1), 100 ].min
  end
end
