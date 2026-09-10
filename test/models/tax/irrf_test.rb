require "test_helper"

class Tax::IrrfTest < ActiveSupport::TestCase
  Y2026 = Date.new(2026, 6, 1)
  Y2025 = Date.new(2025, 6, 1)

  def irrf(gross, on:, dependents: 0)
    inss = Tax::Inss.new(gross: gross, on: on).amount
    Tax::Irrf.new(gross: gross, inss: inss, dependents: dependents, on: on)
  end

  # O pró-labore que fecha os 28% da empresa de R$17 mil/mês cai dentro da
  # isenção de 2026 — é o que torna a jogada tão vantajosa para ela.
  test "abaixo do teto de isenção de 2026 não paga nada" do
    assert_equal 0, irrf(4_760, on: Y2026).amount
    assert_equal BigDecimal("1.0"), irrf(4_760, on: Y2026).reduction_factor
  end

  # A mesma remuneração em 2025 pagava: a isenção é o que mudou.
  test "o mesmo valor em 2025 paga imposto" do
    assert_equal BigDecimal("258.89"), irrf(4_760, on: Y2025).amount
  end

  test "acima do fim da redução parcial paga o imposto cheio" do
    calc = irrf(8_000, on: Y2026)

    assert_equal 0, calc.reduction_factor
    assert_equal calc.progressive_tax, calc.amount
    assert_equal BigDecimal("1049.27"), calc.amount
  end

  test "no meio da faixa de transição paga metade" do
    calc = irrf(6_175, on: Y2026)   # ponto médio entre 5.000 e 7.350

    assert_equal BigDecimal("0.5"), calc.reduction_factor
    assert_equal BigDecimal("301.30"), calc.amount
  end

  test "a redução cresce conforme o valor cai dentro da faixa" do
    maior = irrf(7_000, on: Y2026).reduction_factor
    menor = irrf(5_500, on: Y2026).reduction_factor

    assert_operator menor, :>, maior
  end

  # Duas contas concorrem e vale a menor base.
  test "sem dependentes o desconto simplificado ganha" do
    calc = irrf(4_760, on: Y2025)

    assert_equal BigDecimal("4152.80"), calc.base   # 4.760 − 607,20
  end

  test "com dependentes suficientes as deduções legais passam a ganhar" do
    calc = irrf(8_000, on: Y2026, dependents: 3)

    assert_equal BigDecimal("6551.23"), calc.base   # 8.000 − 880 − 3 × 189,59
    assert_operator calc.amount, :<, irrf(8_000, on: Y2026).amount
  end

  test "base nunca fica negativa" do
    assert_operator irrf(300, on: Y2025).base, :>=, 0
    assert_equal 0, irrf(300, on: Y2025).amount
  end

  test "faixa isenta da tabela progressiva não gera imposto" do
    assert_equal 0, irrf(1_000, on: Y2025).amount
  end
end
