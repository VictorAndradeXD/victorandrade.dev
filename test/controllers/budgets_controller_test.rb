require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = @user.accounts.create!(name: "Conta", kind: "checking")
    sign_in_as @user
  end

  test "o orçamento abre, com e sem lançamentos" do
    get budget_path(month: "2026-02")
    assert_response :success

    @user.transactions.create!(kind: "expense", amount: 80, description: "Luz", occurred_on: Date.new(2026, 2, 3),
                               account: @account, budget_category: "fixed_costs")
    get budget_path(month: "2026-02", categoria: "comfort")
    assert_response :success
    assert_select "h3", "Conforto"
  end

  test "a aba de metas abre e salva quando a soma fecha" do
    get edit_budget_goals_path
    assert_response :success

    patch budget_goals_path, params: { month: "2026-02", budget_goals: Budget.default_percents.merge("pleasures" => 5) }
    assert_redirected_to budget_path(month: "2026-02")
    assert_equal 5, @user.budget_goals.find_by(category: "pleasures").percent
  end

  test "metas acima de 100% voltam com o aviso e nada é salvo" do
    patch budget_goals_path, params: { budget_goals: Budget.default_percents.merge("pleasures" => 20) }

    assert_response :unprocessable_entity
    assert_match "passou de 100% em 10 pontos", response.body
    assert_empty @user.budget_goals
  end

  test "renda ajustada é salva e, apagada, volta a ser a soma das receitas" do
    patch budget_income_path, params: { month: "2026-02", budget_income: { amount: "4500" } }
    assert_equal 4500, @user.budget_incomes.sole.amount

    patch budget_income_path, params: { month: "2026-02", budget_income: { amount: "" } }
    assert_empty @user.budget_incomes
  end

  test "cadastra um modelo e preenche o mês" do
    post budget_presets_path, params: { month: "2026-02",
                                        budget_preset: { category: "fixed_costs", description: "Aluguel", amount: "1000" } }
    assert_redirected_to budget_path(month: "2026-02", categoria: "fixed_costs")

    assert_difference -> { @user.transactions.count }, 1 do
      post fill_budget_presets_path, params: { month: "2026-02" }
    end
    assert_equal "fixed_costs", @user.transactions.sole.budget_category
  end

  test "modelo inválido devolve o painel com o erro" do
    post budget_presets_path, params: { budget_preset: { category: "fixed_costs", description: "", amount: "0" } }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#budget_presets"
  end

  test "não mexe no modelo de outro usuário" do
    preset = users(:two).budget_presets.create!(category: "comfort", description: "Carro", amount: 10)

    delete budget_preset_path(preset)
    assert_response :not_found
    assert BudgetPreset.exists?(preset.id)
  end

  test "quem não tem acesso ao Denfis não vê o orçamento" do
    sign_out
    sign_in_as users(:contadora)

    get budget_path
    assert_redirected_to contabil_path
  end
end
