require "test_helper"

class Accounting::DocumentsTest < ActiveSupport::TestCase
  def company(cnpj) = Accounting::Company.new(name: "Teste", cnpj: cnpj, started_on: Date.new(2025, 1, 1))

  test "aceita CNPJ com dígito verificador correto, com ou sem máscara" do
    assert company("11.222.333/0001-81").valid?
    assert company("11222333000181").valid?
  end

  test "recusa CNPJ com dígito verificador errado" do
    record = company("11.222.333/0001-82")

    assert_not record.valid?
    assert_includes record.errors[:cnpj], "não é um CNPJ válido"
  end

  test "recusa CNPJ de dígitos repetidos, que fecha a conta mas não existe" do
    assert_not company("11111111111111").valid?
  end

  test "guarda só os dígitos e formata na leitura" do
    record = company("11.222.333/0001-81")
    record.validate

    assert_equal "11222333000181", record.cnpj
    assert_equal "11.222.333/0001-81", record.cnpj_formatted
  end

  test "aceita e recusa CPF pelo dígito verificador" do
    empresa = Accounting::Company.create!(name: "Teste", cnpj: "11222333000181", started_on: Date.new(2025, 1, 1))

    assert empresa.partners.build(name: "Sócio", cpf: "529.982.247-25").valid?
    assert_not empresa.partners.build(name: "Sócio", cpf: "529.982.247-26").valid?
    assert_not empresa.partners.build(name: "Sócio", cpf: "111.111.111-11").valid?
  end
end
