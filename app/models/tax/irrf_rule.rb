# Parâmetros do IRRF que não são faixa: dedução por dependente, desconto
# simplificado e a isenção com redução parcial introduzida em 2026.
class Tax::IrrfRule < ApplicationRecord
  include Tax::Effective

  has_many :brackets, class_name: "Tax::IrrfBracket",
           foreign_key: :tax_irrf_rule_id, dependent: :destroy, inverse_of: :rule

  validates :dependent_deduction, :simplified_discount, :valid_from, presence: true

  def self.for(on:)
    effective_on(on).order(valid_from: :desc).first ||
      raise(Tax::MissingRule.for("regra de IRRF", on))
  end

  # A faixa progressiva em que uma base de cálculo cai.
  def bracket_for(base)
    brackets.detect { |b| b.base_from <= base && (b.base_to.nil? || base <= b.base_to) } ||
      raise(Tax::MissingRule.for("faixa de IRRF para base de #{base}", valid_from))
  end
end
