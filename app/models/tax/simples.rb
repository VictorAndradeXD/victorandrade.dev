# Quanto a empresa paga de DAS num anexo, para uma receita bruta de 12 meses.
#
# A alíquota que vale é a EFETIVA, nunca a nominal da faixa: a partir da segunda
# faixa existe parcela a deduzir, e usar a nominal superestima o imposto.
#
#   efetiva = (RBT12 × nominal − parcela a deduzir) ÷ RBT12
class Tax::Simples
  attr_reader :anexo, :rbt12, :on

  def initialize(anexo:, rbt12:, on: Date.current)
    @anexo = anexo
    @rbt12 = rbt12.to_d
    @on    = on
  end

  def bracket
    @bracket ||= Tax::AnexoBracket.for(anexo: anexo, rbt12: rbt12, on: on)
  end

  def annual_das
    @annual_das ||= [ (rbt12 * bracket.rate) - bracket.deduction, 0.to_d ].max.round(2)
  end

  def effective_rate
    return 0.to_d if rbt12.zero?

    (annual_das / rbt12).round(6)
  end
end
