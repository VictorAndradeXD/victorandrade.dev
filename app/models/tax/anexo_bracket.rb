# Uma faixa de um anexo do Simples Nacional.
class Tax::AnexoBracket < ApplicationRecord
  include Tax::Effective

  ANEXO_III = "III".freeze  # o barato
  ANEXO_V   = "V".freeze    # o caro

  validates :anexo, inclusion: { in: [ ANEXO_III, ANEXO_V ] }
  validates :rate, :rbt12_from, :valid_from, presence: true

  # A faixa em que uma receita de 12 meses cai. `rbt12_to` nulo é a última.
  def self.for(anexo:, rbt12:, on:)
    bracket = effective_on(on)
      .where(anexo: anexo)
      .where(rbt12_from: ..rbt12)
      .where("rbt12_to IS NULL OR rbt12_to >= ?", rbt12)
      .order(rbt12_from: :desc)
      .first

    bracket || raise(Tax::MissingRule.for("faixa do Anexo #{anexo} para RBT12 de #{rbt12}", on))
  end
end
