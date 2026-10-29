class BudgetGoalsController < ApplicationController
  include BudgetMonth

  before_action :require_denfis_access
  before_action :set_budget

  def edit
    @goal_set = BudgetGoalSet.new(current_user)
  end

  def update
    @goal_set = BudgetGoalSet.new(current_user, params.expect(budget_goals: Budget::CATEGORY_KEYS))
    return redirect_to budget_path(month: budget_month_param), notice: "Metas salvas." if @goal_set.save

    render :edit, status: :unprocessable_entity
  end

  private
    # A renda do mês só serve para mostrar quanto cada percentual vale em reais.
    def set_budget = @budget = Budget.new(current_user, budget_month)
end
