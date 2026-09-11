# Um mês de uma empresa: quanto ela faturou e quanto pagou de pró-labore.
class Accounting::Competencia < ApplicationRecord
  # Ver a nota em Accounting::Company: o namespace organiza o código e fica
  # fora da URL e dos nomes de parâmetro.
  def self.model_name = ActiveModel::Name.new(self, nil, "Competencia")

  belongs_to :company
  # `inverse_of` explícito: com foreign_key customizado o Rails não o infere, e
  # sem ele o pró-labore aninhado não enxerga a competência durante a validação
  # — o cálculo de INSS e IRRF sairia pela cláusula de guarda, silenciosamente.
  has_many :prolabores, dependent: :destroy, foreign_key: :competencia_id, inverse_of: :competencia

  # Competência é mês, não data: o dia 1 é a forma canônica de guardar isso, e
  # deixa a comparação por intervalo direta.
  normalizes :month, with: ->(value) { value&.beginning_of_month }

  # O <input type="month"> manda "2026-06", sem dia. O cast de data do Rails não
  # reconhece esse formato e devolve nil silenciosamente — o registro falhava na
  # validação de presença sem que nada no formulário explicasse o motivo.
  # Completa o dia antes de deixar o Rails converter.
  def month=(value)
    value = "#{value}-01" if value.is_a?(String) && value.match?(/\A\d{4}-\d{2}\z/)

    super(value)
  end

  # O formulário mostra um campo por sócio, inclusive os que ainda não têm
  # lançamento no mês.
  accepts_nested_attributes_for :prolabores, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["gross"].blank? && attrs["id"].blank? }

  validates :month, presence: true, uniqueness: { scope: :company_id }
  validates :gross_revenue, numericality: { greater_than_or_equal_to: 0 }

  scope :until_month, ->(month) { where(month: ...month.beginning_of_month) }
  scope :chronological, -> { order(:month) }

  def label = I18n.l(month, format: "%B/%Y").capitalize

  def folha = prolabores.sum(:gross)

  # Campo de pró-labore esvaziado no formulário quer dizer "não houve
  # pró-labore neste mês". Apaga o lançamento em vez de tentar gravar zero, que
  # o check constraint `gross > 0` recusaria com um erro sem sentido para quem
  # só apagou um campo.
  def prolabores_attributes=(attributes)
    cleaned = attributes.respond_to?(:values) ? attributes.values : attributes

    marked = cleaned.map do |attrs|
      attrs = attrs.to_h.stringify_keys
      attrs["_destroy"] = "1" if attrs["id"].present? && attrs["gross"].blank?
      attrs
    end

    super(marked)
  end
end
