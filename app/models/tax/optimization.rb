# Responde a pergunta que o módulo existe para responder: quanto de pró-labore
# esta empresa precisa pagar para sair do Anexo V, e isso compensa?
#
# A comparação honesta não é "quanto economizo no DAS". O pró-labore em si não é
# custo — o dinheiro chega ao sócio de qualquer jeito, antes como distribuição
# de lucros. O que se paga a mais é só o INSS e o IRRF sobre ele. Por isso o
# saldo é economia no DAS menos esses dois, e nada além.
#
# A vantagem não é infinita: conforme o faturamento cresce, o pró-labore de 28%
# ultrapassa a faixa isenta do IRRF e a alíquota alta come o ganho, enquanto a
# diferença entre os anexos diminui. É exatamente por isso que esta conta é
# refeita por empresa em vez de virar uma regra fixa.
class Tax::Optimization
  attr_reader :rbt12, :dependents, :on

  def initialize(rbt12:, dependents: 0, on: Date.current)
    @rbt12      = rbt12.to_d
    @dependents = dependents.to_i
    @on         = on
  end

  # Pró-labore mensal que fecha os 28%, nunca abaixo do salário mínimo. Quando
  # o piso manda mais alto do que os 28% pedem, a folha passa do limite — e
  # passar não atrapalha: o degrau já foi vencido.
  def required_monthly_prolabore
    @required_monthly_prolabore ||= [
      (rbt12 * Tax::FatorR::THRESHOLD / 12).round(2),
      inss_rule.minimum_wage
    ].max
  end

  def annual_prolabore = required_monthly_prolabore * 12

  # O piso obrigou a pagar mais do que os 28% exigiam.
  def floored_by_minimum_wage?
    required_monthly_prolabore > (rbt12 * Tax::FatorR::THRESHOLD / 12).round(2)
  end

  def staying   = @staying   ||= Tax::Simples.new(anexo: Tax::AnexoBracket::ANEXO_V,   rbt12: rbt12, on: on)
  def switching = @switching ||= Tax::Simples.new(anexo: Tax::AnexoBracket::ANEXO_III, rbt12: rbt12, on: on)

  def das_saving = (staying.annual_das - switching.annual_das).round(2)

  def monthly_inss = @monthly_inss ||= Tax::Inss.new(gross: required_monthly_prolabore, on: on)

  def monthly_irrf
    @monthly_irrf ||= Tax::Irrf.new(
      gross: required_monthly_prolabore, inss: monthly_inss.amount, dependents: dependents, on: on
    )
  end

  # Mensal arredondado e depois multiplicado por 12, e não o contrário: é assim
  # que o dinheiro sai na vida real, uma guia por mês.
  def annual_inss = (monthly_inss.amount * 12).round(2)
  def annual_irrf = (monthly_irrf.amount * 12).round(2)
  def annual_cost = (annual_inss + annual_irrf).round(2)

  def net_saving = (das_saving - annual_cost).round(2)

  def worth_it? = net_saving.positive?

  def monthly_net_saving = (net_saving / 12).round(2)

  private
    def inss_rule = @inss_rule ||= Tax::InssRule.for(on: on)
end
