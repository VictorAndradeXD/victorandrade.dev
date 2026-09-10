class Accounting::Company < ApplicationRecord
  has_many :partners,    dependent: :destroy
  has_many :competencias, dependent: :destroy

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
