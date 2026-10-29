# Renda de um mês digitada à mão, por cima da soma das receitas lançadas. Útil
# quando o salário ainda não caiu, ou quando parte das entradas não deve virar
# orçamento (um reembolso, uma venda pontual).
class BudgetIncome < ApplicationRecord
  belongs_to :user

  normalizes :month, with: ->(date) { date.beginning_of_month }

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
