require "test_helper"

class Accounting::ProlaboreTest < ActiveSupport::TestCase
  setup do
    @company = Accounting::Company.create!(
      name: "Empresa Teste", cnpj: "11222333000181", started_on: Date.new(2025, 1, 1)
    )
    @partner = @company.partners.create!(name: "Sócio", cpf: "52998224725")
    @competencia = @company.competencias.create!(month: Date.new(2026, 6, 1), gross_revenue: 17_000)
  end

  test "grava INSS e IRRF calculados no lançamento" do
    prolabore = @competencia.prolabores.create!(partner: @partner, gross: 4_760)

    assert_equal BigDecimal("523.60"), prolabore.inss
    assert_equal 0, prolabore.irrf                      # dentro da isenção de 2026
    assert_equal BigDecimal("4236.40"), prolabore.net
  end

  test "dependentes do sócio entram na conta do IRRF" do
    @partner.update!(dependents_count: 3)
    prolabore = @competencia.prolabores.create!(partner: @partner, gross: 8_000)

    assert_equal BigDecimal("892.86"), prolabore.irrf
  end

  # O que foi recolhido foi recolhido: a tabela do ano seguinte não reescreve.
  test "os impostos gravados não mudam quando a tabela muda" do
    prolabore = @competencia.prolabores.create!(partner: @partner, gross: 8_000)
    original = prolabore.irrf

    # Os dois juntos porque o check constraint da tabela exige que o fim da
    # redução parcial não fique abaixo do teto de isenção.
    Tax::IrrfRule.for(on: @competencia.month).update!(exempt_up_to: 20_000, phase_out_up_to: 25_000)

    assert_equal original, prolabore.reload.irrf
  end

  test "um sócio só tem um pró-labore por competência" do
    @competencia.prolabores.create!(partner: @partner, gross: 4_760)
    duplicate = @competencia.prolabores.build(partner: @partner, gross: 1_000)

    assert_not duplicate.valid?
  end

  # Sem tabela do período vira erro de validação, não exceção: é problema de
  # cadastro, e quem digitou precisa ver o motivo.
  test "competência sem tabela fiscal recusa o lançamento com mensagem" do
    antiga = @company.competencias.create!(month: Date.new(2010, 1, 1), gross_revenue: 1_000)
    prolabore = antiga.prolabores.build(partner: @partner, gross: 4_760)

    assert_not prolabore.valid?
    assert_match(/Sem regra de INSS vigente/, prolabore.errors.full_messages.join)
  end
end
