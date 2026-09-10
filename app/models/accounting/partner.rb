class Accounting::Partner < ApplicationRecord
  belongs_to :company
  has_many :prolabores, dependent: :destroy

  normalizes :cpf,  with: ->(value) { BrDocument.digits(value) }
  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true
  validates :cpf, presence: true, uniqueness: { scope: :company_id }
  validates :dependents_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate  :cpf_digits_check

  def cpf_formatted = BrDocument.format_cpf(cpf)

  private
    def cpf_digits_check
      return if cpf.blank?

      errors.add(:cpf, "não é um CPF válido") unless BrDocument.valid_cpf?(cpf)
    end
end
