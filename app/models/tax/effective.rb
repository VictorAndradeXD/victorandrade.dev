# Busca por vigência, compartilhada pelas tabelas fiscais. `valid_to` nulo
# significa "ainda em vigor".
module Tax::Effective
  extend ActiveSupport::Concern

  included do
    scope :effective_on, ->(date) {
      where(valid_from: ..date).where("valid_to IS NULL OR valid_to >= ?", date)
    }
  end
end
