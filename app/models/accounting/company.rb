class Accounting::Company < ApplicationRecord
  # As rotas do módulo são /contabil/empresas, sem o segmento "accounting" — o
  # namespace existe para organizar o código, não para aparecer na URL. Sem
  # isto o form_with procuraria contabil_accounting_company_path, e o
  # params.expect esperaria a chave :accounting_company.
  def self.model_name = ActiveModel::Name.new(self, nil, "Company")

  has_many :partners,    dependent: :destroy
  has_many :competencias, dependent: :destroy

  # Sócio entra pelo formulário da empresa: são uma ou duas pessoas por empresa,
  # e uma tela separada só para isso seria burocracia sem ganho.
  accepts_nested_attributes_for :partners, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? && attrs["cpf"].blank? }

  normalizes :cnpj, with: ->(value) { BrDocument.digits(value) }
  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true
  validates :started_on, presence: true
  validates :cnpj, presence: true, uniqueness: true
  validate  :cnpj_digits_check

  scope :active, -> { where(archived: false) }

  def cnpj_formatted = BrDocument.format_cnpj(cnpj)

  # Primeiro dia do mês em que a empresa começou a operar.
  def started_month = started_on&.beginning_of_month

  def window(month:) = Accounting::Window.new(company: self, month: month)

  private
    def cnpj_digits_check
      return if cnpj.blank?

      errors.add(:cnpj, "não é um CNPJ válido") unless BrDocument.valid_cnpj?(cnpj)
    end
end
