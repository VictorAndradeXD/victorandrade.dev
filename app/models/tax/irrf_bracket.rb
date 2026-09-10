# Uma faixa progressiva do IRRF, presa à regra da mesma vigência.
class Tax::IrrfBracket < ApplicationRecord
  belongs_to :rule, class_name: "Tax::IrrfRule", foreign_key: :tax_irrf_rule_id, inverse_of: :brackets

  validates :base_from, :rate, presence: true
end
