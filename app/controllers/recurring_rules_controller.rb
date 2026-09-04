class RecurringRulesController < ApplicationController
  before_action :set_rule, only: %i[edit update destroy materialize]

  def index = @rules = current_user.recurring_rules.includes(:account, :tag).order(:description)

  def new
    @rule = current_user.recurring_rules.build(
      kind: "expense", frequency: "monthly", starts_on: Date.current, day_of_month: Date.current.day
    )
  end

  def edit; end

  def create
    @rule = current_user.recurring_rules.build(rule_params)
    return redirect_to recurring_rules_path, notice: "Recorrência criada." if @rule.save

    render :new, status: :unprocessable_entity
  end

  def update
    return redirect_to recurring_rules_path, notice: "Recorrência atualizada." if @rule.update(rule_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    @rule.destroy
    redirect_to recurring_rules_path, notice: "Recorrência removida.", status: :see_other
  end

  # Gera os lançamentos do mês corrente que ainda não existem.
  def materialize
    created = @rule.materialize!(Date.current.all_month)
    redirect_to recurring_rules_path, notice: "#{created.size} lançamento(s) gerado(s)."
  end

  private
    def set_rule = @rule = current_user.recurring_rules.find(params[:id])

    def rule_params
      params.expect(recurring_rule: [
        :kind, :description, :amount, :frequency, :day_of_month,
        :starts_on, :ends_on, :active, :account_id, :tag_id
      ])
    end
end
