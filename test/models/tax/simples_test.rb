require "test_helper"

class Tax::SimplesTest < ActiveSupport::TestCase
  ON = Date.new(2026, 6, 1)

  # Na primeira faixa não há parcela a deduzir, então efetiva e nominal batem.
  test "primeira faixa: efetiva igual à nominal" do
    simples = Tax::Simples.new(anexo: "V", rbt12: 180_000, on: ON)

    assert_equal BigDecimal("0.155"), simples.effective_rate
    assert_equal BigDecimal("27900.00"), simples.annual_das
  end

  # A partir da segunda, ignorar a parcela a deduzir superestima o imposto.
  test "segunda faixa: a parcela a deduzir derruba a efetiva abaixo da nominal" do
    simples = Tax::Simples.new(anexo: "V", rbt12: 204_000, on: ON)

    assert_equal BigDecimal("32220.00"), simples.annual_das
    assert_in_delta 0.157941, simples.effective_rate, 0.000001
    assert_operator simples.effective_rate, :<, BigDecimal("0.18")
  end

  test "o Anexo III sai muito mais barato na mesma receita" do
    iii = Tax::Simples.new(anexo: "III", rbt12: 204_000, on: ON)

    assert_equal BigDecimal("13488.00"), iii.annual_das
    assert_in_delta 0.066118, iii.effective_rate, 0.000001
  end

  test "a virada de faixa acontece no centavo certo" do
    ultima_da_primeira = Tax::Simples.new(anexo: "V", rbt12: 180_000, on: ON)
    primeira_da_segunda = Tax::Simples.new(anexo: "V", rbt12: 180_000.01, on: ON)

    assert_equal 0, ultima_da_primeira.bracket.deduction
    assert_equal BigDecimal("4500.00"), primeira_da_segunda.bracket.deduction
  end

  test "receita zero não divide por zero" do
    assert_equal 0, Tax::Simples.new(anexo: "V", rbt12: 0, on: ON).effective_rate
  end

  # Melhor estourar do que devolver número errado com cara de verdade.
  test "sem tabela vigente para a data, reclama em vez de inventar" do
    assert_raises Tax::MissingRule do
      Tax::Simples.new(anexo: "V", rbt12: 204_000, on: Date.new(2010, 1, 1)).annual_das
    end
  end
end
