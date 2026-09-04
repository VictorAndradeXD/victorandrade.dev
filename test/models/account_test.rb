require "test_helper"

class AccountTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @account = @user.accounts.create!(name: "Conta", kind: "checking", initial_balance: 100)
  end

  def lancar(kind, amount, on: Date.current)
    @user.transactions.create!(kind: kind, description: "x", amount: amount,
                               occurred_on: on, account: @account)
  end

  test "saldo parte do aporte inicial e soma entradas menos saídas" do
    lancar("income", 500)
    lancar("expense", 200)

    assert_equal 400, @account.balance
  end

  test "saldo até uma data ignora o que vem depois" do
    lancar("income", 500, on: Date.new(2026, 1, 10))
    lancar("expense", 200, on: Date.new(2026, 2, 10))

    assert_equal 600, @account.balance(up_to: Date.new(2026, 1, 31))
    assert_equal 400, @account.balance(up_to: Date.new(2026, 2, 28))
  end

  test "conta sem lançamento vale o aporte inicial" do
    assert_equal 100, @account.balance
  end

  test "nome é único por usuário, mas não entre usuários" do
    duplicada = @user.accounts.build(name: "Conta", kind: "wallet")
    assert_not duplicada.valid?

    de_outro = users(:two).accounts.build(name: "Conta", kind: "wallet")
    assert de_outro.valid?
  end

  test "não apaga conta que ainda tem lançamento" do
    lancar("expense", 10)

    assert_no_difference -> { Account.count } do
      @account.destroy
    end
    assert @account.errors.any?
  end

  test "arquivada some do escopo ativo mas continua no saldo" do
    lancar("income", 50)
    @account.update!(archived: true)

    assert_empty @user.accounts.active
    assert_equal 150, @account.balance
  end

  # Com `validate: true` o enum não levanta exceção: acusa erro de validação.
  test "só aceita os tipos conhecidos, e o banco também recusa" do
    invalida = @user.accounts.build(name: "Cripto", kind: "cripto")
    assert_not invalida.valid?
    assert_includes invalida.errors.attribute_names, :kind

    erro = assert_raises(ActiveRecord::StatementInvalid) do
      @account.update_column(:kind, "cripto")
    end
    assert_match(/accounts_kind_check/, erro.message)
  end
end
