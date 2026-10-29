require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @account = @user.accounts.create!(name: "Conta", kind: "checking")
    @month   = Date.new(2026, 2, 1)
  end

  def lancar(kind, amount, category: nil, on: @month + 4, description: "Gasto")
    @user.transactions.create!(kind: kind, amount: amount, budget_category: category,
                               description: description, occurred_on: on, account: @account)
  end

  test "sem nada salvo, as metas são as da planilha e somam 100%" do
    set = BudgetGoalSet.new(@user)

    assert_equal 30, set.percents["fixed_costs"]
    assert_equal 100, set.total
  end

  test "não salva metas que passam de 100%, e diz quanto passou" do
    set = BudgetGoalSet.new(@user, Budget.default_percents.merge("pleasures" => "20"))

    assert_not set.save
    assert_equal 10, set.excess
    assert_match "passou de 100% em 10 pontos", set.errors.full_messages.first
    assert_empty @user.budget_goals
  end

  test "salva metas que somam menos de 100% e relê o que foi salvo" do
    assert BudgetGoalSet.new(@user, Budget.default_percents.merge("pleasures" => "0")).save

    assert_equal 0, BudgetGoalSet.new(@user).percents["pleasures"]
    assert_equal 90, BudgetGoalSet.new(@user).total
  end

  test "percentual fora de 0..100 ou que não é número é recusado" do
    assert_not BudgetGoalSet.new(@user, Budget.default_percents.merge("knowledge" => "-5")).valid?
    assert_not BudgetGoalSet.new(@user, Budget.default_percents.merge("knowledge" => "abc")).valid?
  end

  test "renda do mês é a soma das receitas, a não ser que tenha sido ajustada" do
    lancar("income", 5000)
    lancar("income", 331.30)
    lancar("income", 9999, on: @month.next_month)

    assert_equal BigDecimal("5331.30"), Budget.new(@user, @month).income

    @user.budget_incomes.create!(month: @month + 10, amount: 4000)
    budget = Budget.new(@user, @month)
    assert_equal 4000, budget.income
    assert budget.income_adjusted?
  end

  test "cada meta compara o gasto do mês com a fatia da renda" do
    lancar("income", 5331.30)
    lancar("expense", 1000, category: "fixed_costs")
    lancar("expense", 200, category: "fixed_costs")
    lancar("expense", 50)

    budget = Budget.new(@user, @month)
    fixos = budget.rows.find { it.category.key == "fixed_costs" }

    assert_equal BigDecimal("1599.39"), fixos.planned
    assert_equal 1200, fixos.spent
    assert_in_delta 0.7503, fixos.used.to_f, 0.0001
    assert_equal 50, budget.unassigned_spent
    assert_equal 1250, budget.total_spent
  end

  test "receita nunca fica com meta, mesmo que o formulário mande uma" do
    assert_nil lancar("income", 100, category: "comfort").budget_category
  end

  test "parcelamento leva a meta para as parcelas" do
    plan = @user.installment_plans.create!(kind: "expense", description: "Curso", total_amount: 300,
                                           installments_count: 3, first_due_on: @month, account: @account,
                                           budget_category: "knowledge")

    assert_equal [ "knowledge" ] * 3, plan.transactions.pluck(:budget_category)
  end

  test "preencher lança cada modelo uma vez e respeita o gasto já lançado com o mesmo nome" do
    @user.budget_presets.create!(category: "fixed_costs", description: "Aluguel", amount: 1000)
    @user.budget_presets.create!(category: "comfort", description: "Parcela do carro", amount: 700)
    lancar("expense", 1100, description: "aluguel")

    created = BudgetPreset.fill!(user: @user, month: @month, account: @account)

    assert_equal [ "Parcela do carro" ], created.map(&:description)
    assert_equal "comfort", created.first.budget_category
    assert_equal @month, created.first.occurred_on
    assert_empty BudgetPreset.fill!(user: @user, month: @month, account: @account)
  end

  test "dois modelos com o mesmo nome, mesmo em caixa diferente, não podem existir" do
    @user.budget_presets.create!(category: "fixed_costs", description: "Luz", amount: 100)

    assert_not @user.budget_presets.build(category: "comfort", description: "LUZ", amount: 50).valid?
  end
end
