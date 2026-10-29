class BudgetIncomesController < ApplicationController
  include BudgetMonth

  before_action :require_denfis_access

  # Campo vazio volta para a soma das receitas lançadas.
  def update
    amount = params.dig(:budget_income, :amount)
    income = current_user.budget_incomes.find_or_initialize_by(month: budget_month)

    if amount.blank?
      income.destroy if income.persisted?
      notice = "Renda do mês voltou a ser a soma das receitas."
    elsif income.update(amount: amount)
      notice = "Renda do mês ajustada."
    else
      return redirect_to budget_path(month: budget_month_param), alert: "Renda inválida: #{income.errors.full_messages.to_sentence}."
    end

    redirect_to budget_path(month: budget_month_param), notice: notice
  end
end
