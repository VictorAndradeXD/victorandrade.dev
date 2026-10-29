class BudgetsController < ApplicationController
  include BudgetMonth

  before_action :require_denfis_access

  def show
    @month    = budget_month
    @budget   = Budget.new(current_user, @month)
    @category = Budget.category(params[:categoria]) || Budget::CATEGORIES.first
    @preset   = current_user.budget_presets.build(category: @category.key)
  end
end
