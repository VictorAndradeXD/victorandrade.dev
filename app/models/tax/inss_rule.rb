# Alíquota e teto do INSS do contribuinte individual, mais o salário mínimo
# vigente — que é o piso do pró-labore. Andam juntos porque viram no mesmo dia.
class Tax::InssRule < ApplicationRecord
  include Tax::Effective

  validates :rate, :ceiling, :minimum_wage, :valid_from, presence: true

  def self.for(on:)
    effective_on(on).order(valid_from: :desc).first ||
      raise(Tax::MissingRule.for("regra de INSS", on))
  end
end
