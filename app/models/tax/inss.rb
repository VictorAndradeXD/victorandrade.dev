# INSS retido do sócio sobre o pró-labore: alíquota fixa até o teto do salário
# de contribuição. Acima do teto o valor congela — é o que torna o custo
# marginal do pró-labore alto muito menor do que parece.
class Tax::Inss
  attr_reader :gross, :on

  def initialize(gross:, on: Date.current)
    @gross = gross.to_d
    @on    = on
  end

  def rule = @rule ||= Tax::InssRule.for(on: on)

  def base = [ gross, rule.ceiling ].min

  def amount = (base * rule.rate).round(2)

  # Verdadeiro quando o pró-labore já passou do teto: dali para cima só o IRRF
  # cresce.
  def capped? = gross > rule.ceiling
end
