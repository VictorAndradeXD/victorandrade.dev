# A janela móvel de 12 meses de uma empresa num mês de apuração.
#
# Duas sutilezas que o cálculo à mão costuma errar:
#
# 1. O RBT12 são os 12 meses ANTERIORES ao mês apurado, não os 12 terminando
#    nele. Setembro de 2026 olha de setembro/2025 a agosto/2026.
#
# 2. Empresa com menos de 12 meses de vida não tem janela cheia: a receita é
#    PROPORCIONALIZADA — média dos meses corridos vezes 12. Sem isso, uma
#    empresa nova pareceria faturar pouco e cairia numa faixa que não é a dela.
#    A segunda empresa da carteira vai precisar disso em 2027.
class Accounting::Window
  attr_reader :company, :month

  def initialize(company:, month:)
    @company = company
    @month   = month.beginning_of_month
  end

  # Meses completos de atividade antes do mês apurado.
  def elapsed_months
    return 0 if company.started_month.nil? || company.started_month >= month

    (month.year * 12 + month.month) - (company.started_month.year * 12 + company.started_month.month)
  end

  def proportional? = elapsed_months < 12

  def rbt12   = annualize(prior_revenue, current_revenue)
  def folha12 = annualize(prior_folha,   current_folha)

  def fator_r = @fator_r ||= Tax::FatorR.new(folha12: folha12, rbt12: rbt12)

  def anexo = fator_r.anexo

  def simples = Tax::Simples.new(anexo: anexo, rbt12: rbt12, on: month)

  # O simulador assume um sócio só, que é o caso das duas empresas da carteira.
  # Com mais de um, o pró-labore teria que ser repartido entre eles e a conta de
  # IRRF muda — por isso os dependentes vêm do sócio único, não de uma soma.
  def optimization
    Tax::Optimization.new(rbt12: rbt12, dependents: sole_partner_dependents, on: month)
  end

  private
    def window_start = proportional? ? company.started_month : (month << 12)

    def prior_competencias = company.competencias.where(month: window_start...month)

    def prior_revenue = prior_competencias.sum(:gross_revenue)

    def prior_folha
      Accounting::Prolabore.where(competencia_id: prior_competencias.select(:id)).sum(:gross)
    end

    def current_competencia
      @current_competencia ||= company.competencias.find_by(month: month)
    end

    def current_revenue = current_competencia&.gross_revenue.to_d

    def current_folha = current_competencia ? current_competencia.folha : 0.to_d

    # No primeiro mês não há histórico nenhum: a regra manda anualizar o próprio
    # mês. Nos demais meses do primeiro ano, anualiza a média do que já correu.
    def annualize(prior_total, current_value)
      return (current_value.to_d * 12).round(2) if elapsed_months.zero?
      return prior_total.to_d.round(2)          unless proportional?

      ((prior_total.to_d / elapsed_months) * 12).round(2)
    end

    def sole_partner_dependents = company.partners.first&.dependents_count.to_i
end
