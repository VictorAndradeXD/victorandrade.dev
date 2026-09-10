# IRRF sobre o pró-labore.
#
# Duas contas concorrem e vale a que gera menos imposto: deduções legais (INSS
# mais dependentes) ou desconto simplificado. Depois disso, desde 2026 existe
# isenção total até um teto e redução parcial até outro.
#
# ATENÇÃO: a redução parcial está modelada como interpolação linear entre os
# dois tetos. A lei define um redutor com fórmula própria — esta aproximação
# acerta os extremos (zero no teto de isenção, imposto cheio no fim da faixa) e
# aproxima o meio. Precisa ser conferida pela contadora antes de o número valer
# como oficial. Corrigir é trocar só #reduction_factor.
class Tax::Irrf
  attr_reader :gross, :inss, :dependents, :on

  def initialize(gross:, inss:, dependents: 0, on: Date.current)
    @gross      = gross.to_d
    @inss       = inss.to_d
    @dependents = dependents.to_i
    @on         = on
  end

  def rule = @rule ||= Tax::IrrfRule.for(on: on)

  # A menor das duas bases, nunca negativa.
  def base
    legal      = gross - inss - (dependents * rule.dependent_deduction)
    simplified = gross - rule.simplified_discount

    [ [ legal, simplified ].min, 0.to_d ].max
  end

  def progressive_tax
    bracket = rule.bracket_for(base)

    [ (base * bracket.rate) - bracket.deduction, 0.to_d ].max.round(2)
  end

  # 1 = isento por completo, 0 = imposto cheio.
  def reduction_factor
    return 0.to_d if rule.exempt_up_to.nil?
    return 1.to_d if gross <= rule.exempt_up_to
    return 0.to_d if rule.phase_out_up_to.nil? || gross >= rule.phase_out_up_to

    span = rule.phase_out_up_to - rule.exempt_up_to
    return 0.to_d if span <= 0

    ((rule.phase_out_up_to - gross) / span).round(6)
  end

  def amount = (progressive_tax * (1 - reduction_factor)).round(2)

  def exempt? = amount.zero?
end
