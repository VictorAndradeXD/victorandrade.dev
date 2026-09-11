require "test_helper"

class Accounting::CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:contadora)
    @company = Accounting::Company.create!(
      name: "Empresa Teste", cnpj: "11222333000181", started_on: Date.new(2024, 1, 1)
    )
    @partner = @company.partners.create!(name: "Sócio", cpf: "52998224725")
  end

  test "a carteira abre vazia sem quebrar" do
    @company.destroy!
    get contabil_path

    assert_response :success
    assert_select "a[href=?]", new_contabil_company_path
  end

  test "a carteira lista as empresas com o fator R" do
    get contabil_path

    assert_response :success
    assert_select "h2", "Empresa Teste"
  end

  test "o painel abre mesmo sem nenhuma competência lançada" do
    get contabil_company_path(@company)

    assert_response :success
  end

  test "o painel mostra a simulação de migração para quem está no Anexo V" do
    seed_history(revenue: 17_000)
    get contabil_company_path(@company, month: "2026-09")

    assert_response :success
    assert_select "h2", "Simulação de migração"
    assert_match "R$ 4.760,00", response.body      # pró-labore que fecha os 28%
    assert_match "R$ 12.448,80", response.body     # saldo líquido no ano
  end

  test "quem já está no Anexo III vê o texto de manutenção, não o de migração" do
    seed_history(revenue: 17_000, prolabore: 4_760)
    get contabil_company_path(@company, month: "2026-09")

    assert_response :success
    assert_select "h2", "Manutenção do Anexo III"
  end

  test "mês inválido na URL cai no mês corrente em vez de estourar" do
    get contabil_company_path(@company, month: "nao-e-um-mes")

    assert_response :success
  end

  test "cadastra empresa com sócio no mesmo formulário" do
    assert_difference [ "Accounting::Company.count", "Accounting::Partner.count" ], 1 do
      post contabil_companies_path, params: {
        company: {
          name: "Nova", cnpj: "45.723.174/0001-10", started_on: "2026-01-01",
          partners_attributes: { "0" => { name: "Dono", cpf: "529.982.247-25", dependents_count: 0 } }
        }
      }
    end

    assert_redirected_to contabil_company_path(Accounting::Company.order(:id).last)
  end

  test "CNPJ com dígito errado volta para o formulário com o motivo" do
    assert_no_difference "Accounting::Company.count" do
      post contabil_companies_path, params: {
        company: { name: "Nova", cnpj: "11.222.333/0001-82", started_on: "2026-01-01" }
      }
    end

    assert_response :unprocessable_entity
    assert_match "não é um CNPJ válido", response.body
  end

  test "o dono do Denfis não entra na carteira" do
    sign_in_as users(:one)
    get contabil_path

    assert_redirected_to denfis_root_path
  end

  private
    # 12 meses fechados antes de setembro/2026.
    def seed_history(revenue:, prolabore: nil)
      12.downto(1) do |i|
        competencia = @company.competencias.create!(
          month: Date.new(2026, 9, 1) << i, gross_revenue: revenue
        )
        competencia.prolabores.create!(partner: @partner, gross: prolabore) if prolabore
      end
    end
end
