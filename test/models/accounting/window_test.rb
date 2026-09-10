require "test_helper"

# A janela móvel de 12 meses. Os três cenários abaixo foram montados para
# convergirem no MESMO RBT12 de R$204.000 — empresa madura, empresa nova com
# meses corridos e empresa no primeiro mês. Se a proporcionalização estiver
# certa, as três chegam lá por caminhos diferentes.
class Accounting::WindowTest < ActiveSupport::TestCase
  REFERENCE = Date.new(2026, 9, 1)
  MONTHLY_REVENUE = 17_000
  MONTHLY_PROLABORE = 4_760

  def build_company(started_on:, months:, revenue: MONTHLY_REVENUE, prolabore: nil)
    company = Accounting::Company.create!(
      name: "Empresa Teste", cnpj: "11222333000181", started_on: started_on
    )
    partner = company.partners.create!(name: "Sócio", cpf: "52998224725")

    months.each do |month|
      competencia = company.competencias.create!(month: month, gross_revenue: revenue)
      next if prolabore.nil?

      competencia.prolabores.create!(partner: partner, gross: prolabore)
    end

    company
  end

  def months_before(reference, count) = count.downto(1).map { |i| reference << i }

  test "empresa madura soma os 12 meses anteriores ao mês apurado" do
    company = build_company(started_on: Date.new(2024, 1, 1), months: months_before(REFERENCE, 12))
    window  = company.window(month: REFERENCE)

    assert_equal 32, window.elapsed_months     # janela cheia de sobra
    assert_not window.proportional?
    assert_equal BigDecimal("204000.00"), window.rbt12
  end

  # O mês apurado não entra no próprio RBT12.
  test "a receita do mês apurado fica de fora" do
    company = build_company(started_on: Date.new(2024, 1, 1), months: months_before(REFERENCE, 12))
    company.competencias.create!(month: REFERENCE, gross_revenue: 999_999)

    assert_equal BigDecimal("204000.00"), company.window(month: REFERENCE).rbt12
  end

  test "empresa nova anualiza a média dos meses corridos" do
    company = build_company(started_on: Date.new(2026, 4, 1), months: months_before(REFERENCE, 5))
    window  = company.window(month: REFERENCE)

    assert_equal 5, window.elapsed_months
    assert window.proportional?
    assert_equal BigDecimal("204000.00"), window.rbt12   # (85.000 ÷ 5) × 12
  end

  test "no primeiro mês de atividade anualiza o próprio mês" do
    company = build_company(started_on: REFERENCE, months: [])
    company.competencias.create!(month: REFERENCE, gross_revenue: MONTHLY_REVENUE)
    window = company.window(month: REFERENCE)

    assert_equal 0, window.elapsed_months
    assert window.proportional?
    assert_equal BigDecimal("204000.00"), window.rbt12
  end

  test "o fator R sai da folha e da receita da mesma janela" do
    company = build_company(
      started_on: Date.new(2024, 1, 1), months: months_before(REFERENCE, 12),
      prolabore: MONTHLY_PROLABORE
    )
    window = company.window(month: REFERENCE)

    assert_equal BigDecimal("57120.00"), window.folha12
    assert_equal BigDecimal("0.28"), window.fator_r.value
    assert window.fator_r.reaches?
    assert_equal "III", window.anexo
  end

  test "sem pró-labore a empresa fica no Anexo V" do
    company = build_company(started_on: Date.new(2024, 1, 1), months: months_before(REFERENCE, 12))
    window  = company.window(month: REFERENCE)

    assert_equal 0, window.folha12
    assert_equal "V", window.anexo
    assert_equal BigDecimal("32220.00"), window.simples.annual_das
  end

  test "o simulador sai pronto da janela, com os números da empresa" do
    company = build_company(started_on: Date.new(2024, 1, 1), months: months_before(REFERENCE, 12))
    optimization = company.window(month: REFERENCE).optimization

    assert_equal BigDecimal("4760.00"),  optimization.required_monthly_prolabore
    assert_equal BigDecimal("12448.80"), optimization.net_saving
    assert optimization.worth_it?
  end
end
