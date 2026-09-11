require "test_helper"

class Accounting::CompetenciasControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:contadora)
    @company = Accounting::Company.create!(
      name: "Empresa Teste", cnpj: "11222333000181", started_on: Date.new(2024, 1, 1)
    )
    @partner = @company.partners.create!(name: "Sócio", cpf: "52998224725")
  end

  test "a lista abre vazia sem quebrar" do
    get contabil_company_competencias_path(@company)

    assert_response :success
  end

  test "o formulário traz um campo por sócio, mesmo sem lançamento ainda" do
    get new_contabil_company_competencia_path(@company)

    assert_response :success
    assert_select "input[name=?]", "competencia[prolabores_attributes][0][gross]"
  end

  test "lança competência com receita e pró-labore, gravando os impostos" do
    assert_difference "Accounting::Prolabore.count", 1 do
      post contabil_company_competencias_path(@company), params: {
        competencia: {
          month: "2026-06", gross_revenue: "17000",
          prolabores_attributes: { "0" => { partner_id: @partner.id, gross: "4760" } }
        }
      }
    end

    assert_redirected_to contabil_company_competencias_path(@company)
    prolabore = Accounting::Prolabore.order(:id).last
    assert_equal BigDecimal("523.60"), prolabore.inss
    assert_equal 0, prolabore.irrf
  end

  test "pró-labore em branco não cria lançamento" do
    assert_no_difference "Accounting::Prolabore.count" do
      post contabil_company_competencias_path(@company), params: {
        competencia: {
          month: "2026-06", gross_revenue: "17000",
          prolabores_attributes: { "0" => { partner_id: @partner.id, gross: "" } }
        }
      }
    end

    assert_redirected_to contabil_company_competencias_path(@company)
  end

  # Apagar o campo quer dizer "não houve pró-labore neste mês": o lançamento
  # some, em vez de tentar gravar zero e esbarrar no check constraint.
  test "esvaziar o pró-labore de uma competência existente apaga o lançamento" do
    competencia = @company.competencias.create!(month: Date.new(2026, 6, 1), gross_revenue: 17_000)
    prolabore = competencia.prolabores.create!(partner: @partner, gross: 4_760)

    assert_difference "Accounting::Prolabore.count", -1 do
      patch contabil_company_competencia_path(@company, competencia), params: {
        competencia: {
          month: "2026-06", gross_revenue: "17000",
          prolabores_attributes: { "0" => { id: prolabore.id, partner_id: @partner.id, gross: "" } }
        }
      }
    end
  end

  test "o mesmo mês duas vezes é recusado" do
    @company.competencias.create!(month: Date.new(2026, 6, 1), gross_revenue: 1_000)

    assert_no_difference "Accounting::Competencia.count" do
      post contabil_company_competencias_path(@company), params: {
        competencia: { month: "2026-06", gross_revenue: "17000" }
      }
    end

    assert_response :unprocessable_entity
  end
end
