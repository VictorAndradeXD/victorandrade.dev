require "test_helper"

class Tax::OptimizationTest < ActiveSupport::TestCase
  ON = Date.new(2026, 6, 1)

  def optimize(rbt12, dependents: 0) = Tax::Optimization.new(rbt12: rbt12, dependents: dependents, on: ON)

  # O caso real da empresa do Judeu: R$17 mil/mês.
  test "a empresa de R$204 mil economiza cerca de R$12,4 mil por ano" do
    o = optimize(204_000)

    assert_equal BigDecimal("4760.00"),  o.required_monthly_prolabore
    assert_equal BigDecimal("32220.00"), o.staying.annual_das
    assert_equal BigDecimal("13488.00"), o.switching.annual_das
    assert_equal BigDecimal("18732.00"), o.das_saving
    assert_equal BigDecimal("6283.20"),  o.annual_inss
    assert_equal 0,                      o.annual_irrf
    assert_equal BigDecimal("12448.80"), o.net_saving
    assert_equal BigDecimal("1037.40"),  o.monthly_net_saving
    assert o.worth_it?
  end

  test "o pró-labore exigido é exatamente 28% do RBT12 dividido por 12" do
    assert_equal BigDecimal("2800.00"), optimize(120_000).required_monthly_prolabore
  end

  # Faturamento baixo: 28% dá menos que o salário mínimo, e o piso manda.
  test "o salário mínimo é o piso do pró-labore" do
    o = optimize(50_000)   # 28% ÷ 12 = R$1.166,67, abaixo do mínimo

    assert_equal BigDecimal("1518.00"), o.required_monthly_prolabore
    assert o.floored_by_minimum_wage?
  end

  test "acima do piso o fator R é que manda" do
    assert_not optimize(204_000).floored_by_minimum_wage?
  end

  # A vantagem não é infinita: em algum ponto o IRRF de 27,5% sobre o
  # pró-labore alto supera a diferença entre os anexos.
  test "em faturamento alto deixa de compensar" do
    assert optimize(600_000).worth_it?
    assert_not optimize(650_000).worth_it?
  end

  test "o saldo encolhe conforme o faturamento sobe dentro da faixa vantajosa" do
    assert_operator optimize(204_000).net_saving, :>, optimize(500_000).net_saving
    assert_operator optimize(500_000).net_saving, :>, optimize(600_000).net_saving
  end

  test "dependentes reduzem o custo e aumentam o saldo" do
    sem  = optimize(500_000)
    com  = optimize(500_000, dependents: 3)

    assert_operator com.annual_irrf, :<, sem.annual_irrf
    assert_operator com.net_saving, :>, sem.net_saving
  end

  # O INSS congela no teto: dali para cima só o IRRF cresce.
  test "pró-labore acima do teto do INSS não aumenta a contribuição" do
    o = optimize(900_000)

    assert o.monthly_inss.capped?
    assert_equal (BigDecimal("8157.41") * BigDecimal("0.11")).round(2) * 12, o.annual_inss
  end
end
