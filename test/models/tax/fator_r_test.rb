require "test_helper"

class Tax::FatorRTest < ActiveSupport::TestCase
  test "exatamente 28% já cai no Anexo III" do
    fator = Tax::FatorR.new(folha12: 57_120, rbt12: 204_000)

    assert_equal BigDecimal("0.28"), fator.value
    assert fator.reaches?
    assert_equal "III", fator.anexo
  end

  # O degrau: um centavo a menos de folha e a empresa fica no anexo caro.
  #
  # Este caso existe por um bug real: a razão era arredondada para 6 casas ANTES
  # da comparação, então 0,27999995 virava 0,280000 e a empresa era classificada
  # no anexo barato sem ter direito. A decisão tem que usar a razão crua.
  test "um fio abaixo do limite continua no Anexo V" do
    fator = Tax::FatorR.new(folha12: 57_119.99, rbt12: 204_000)

    assert_not fator.reaches?
    assert_equal "V", fator.anexo
    assert_equal BigDecimal("0.28"), fator.value, "o valor exibido arredonda, mas não decide"
  end

  test "acima do limite segue no Anexo III" do
    assert Tax::FatorR.new(folha12: 100_000, rbt12: 204_000).reaches?
  end

  test "quanto de folha falta para encostar no limite" do
    fator = Tax::FatorR.new(folha12: 40_000, rbt12: 204_000)

    assert_equal BigDecimal("57120.00"), fator.required_folha
    assert_equal BigDecimal("17120.00"), fator.missing_folha
  end

  test "quem já passou não tem folha faltando" do
    assert_equal 0, Tax::FatorR.new(folha12: 60_000, rbt12: 204_000).missing_folha
  end

  # Empresa recém-aberta passa por aqui antes de faturar o primeiro real.
  test "sem receita o fator é zero em vez de estourar" do
    fator = Tax::FatorR.new(folha12: 10_000, rbt12: 0)

    assert_equal 0, fator.value
    assert_equal "V", fator.anexo
  end
end
