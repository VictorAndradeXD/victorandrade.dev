# Auto preenchimento: um gasto que se repete todo mês (aluguel, luz, a parcela
# do carro), ligado a uma meta. "Preencher" vira cada um num lançamento do mês.
class BudgetPreset < ApplicationRecord
  belongs_to :user

  validates :category, inclusion: { in: Budget::CATEGORY_KEYS }
  validates :description, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :amount, numericality: { greater_than: 0 }

  scope :ordered, -> { order(Arel.sql("lower(description)")) }

  # Lança no dia 1 do mês cada modelo que ainda não tem uma despesa de mesmo
  # nome naquele mês — então preencher de novo não duplica, e um gasto já
  # lançado à mão (talvez com outro valor) não é sobreposto.
  def self.fill!(user:, month:, account:)
    month = month.beginning_of_month
    taken = user.transactions.expense.between(month.all_month)
      .pluck(Arel.sql("lower(description)")).to_set

    transaction do
      user.budget_presets.ordered.reject { taken.include?(it.description.downcase) }.map do |preset|
        user.transactions.create!(
          kind: "expense", account: account, budget_category: preset.category,
          description: preset.description, amount: preset.amount, occurred_on: month
        )
      end
    end
  end
end
