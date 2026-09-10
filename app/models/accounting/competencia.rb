# Um mês de uma empresa: quanto ela faturou e quanto pagou de pró-labore.
class Accounting::Competencia < ApplicationRecord
  belongs_to :company
  has_many :prolabores, dependent: :destroy, foreign_key: :competencia_id

  # Competência é mês, não data: o dia 1 é a forma canônica de guardar isso, e
  # deixa a comparação por intervalo direta.
  normalizes :month, with: ->(value) { value&.beginning_of_month }

  validates :month, presence: true, uniqueness: { scope: :company_id }
  validates :gross_revenue, numericality: { greater_than_or_equal_to: 0 }

  scope :until_month, ->(month) { where(month: ...month.beginning_of_month) }
  scope :chronological, -> { order(:month) }

  def label = I18n.l(month, format: "%B/%Y").capitalize

  def folha = prolabores.sum(:gross)
end
