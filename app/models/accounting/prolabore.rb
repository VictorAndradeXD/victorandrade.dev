# O pró-labore de um sócio numa competência.
#
# INSS e IRRF ficam GRAVADOS, e não recalculados na leitura: a tabela do ano que
# vem não pode reescrever o que já foi recolhido este ano.
class Accounting::Prolabore < ApplicationRecord
  belongs_to :competencia
  belongs_to :partner

  before_validation :compute_taxes

  validates :gross, numericality: { greater_than: 0 }
  validates :partner_id, uniqueness: { scope: :competencia_id,
                                       message: "já tem pró-labore nesta competência" }
  validate :tax_rules_available

  def net = (gross - inss - irrf).round(2)

  private
    def compute_taxes
      return if gross.blank? || competencia.blank?

      on = competencia.month
      self.inss = Tax::Inss.new(gross: gross, on: on).amount
      self.irrf = Tax::Irrf.new(
        gross: gross, inss: inss, dependents: partner&.dependents_count.to_i, on: on
      ).amount
    rescue Tax::MissingRule => e
      @missing_rule = e.message
    end

    # Sem tabela do período não dá para lançar. Vira erro de validação em vez de
    # exceção: é problema de cadastro, e quem digitou precisa ver o motivo.
    def tax_rules_available
      errors.add(:base, @missing_rule) if @missing_rule
    end
end
