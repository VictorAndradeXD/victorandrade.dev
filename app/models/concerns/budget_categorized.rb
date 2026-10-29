# Lançamento (ou regra que gera lançamentos) que pode ser ligado a uma meta do
# orçamento. Só despesa conta para meta: numa receita o campo é limpo, para que
# trocar o tipo no formulário não deixe uma entrada contando como gasto.
module BudgetCategorized
  extend ActiveSupport::Concern

  included do
    normalizes :budget_category, with: ->(value) { value.presence }

    before_validation { self.budget_category = nil if income? }

    validates :budget_category, inclusion: { in: Budget::CATEGORY_KEYS }, allow_nil: true
  end

  def budget_category_name = Budget.category(budget_category)&.name
end
