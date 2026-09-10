require "test_helper"

class Tax::InssTest < ActiveSupport::TestCase
  ON = Date.new(2026, 6, 1)

  test "abaixo do teto retém 11% do bruto" do
    inss = Tax::Inss.new(gross: 4_760, on: ON)

    assert_equal BigDecimal("523.60"), inss.amount
    assert_not inss.capped?
  end

  # A não-linearidade que o simulador precisa respeitar: passando do teto, o
  # custo marginal do pró-labore extra cai para só IRRF.
  test "acima do teto o valor congela" do
    no_teto = Tax::Inss.new(gross: 8_157.41, on: ON)
    acima   = Tax::Inss.new(gross: 20_000,   on: ON)

    assert_equal no_teto.amount, acima.amount
    assert acima.capped?
    assert_not no_teto.capped?
  end

  test "a vigência de 2025 é usada para competência de 2025" do
    assert_equal BigDecimal("1518.00"), Tax::InssRule.for(on: Date.new(2025, 6, 1)).minimum_wage
  end

  test "sem regra para a data, reclama" do
    assert_raises Tax::MissingRule do
      Tax::Inss.new(gross: 5_000, on: Date.new(2010, 1, 1)).amount
    end
  end
end
