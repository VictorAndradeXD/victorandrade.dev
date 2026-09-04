require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @account = @user.accounts.create!(name: "Cartão", kind: "credit_card")
  end

  def build_expense(amount: 3000, **attrs)
    @user.transactions.build(
      kind: "expense", description: "Fatura", amount: amount,
      occurred_on: Date.current, account: @account, **attrs
    )
  end

  test "o detalhamento não pode ultrapassar o valor do lançamento" do
    transaction = build_expense(items_attributes: [
      { description: "gasolina", amount: 2000 },
      { description: "mercado",  amount: 1500 }
    ])

    assert_not transaction.valid?
    assert_match(/ultrapassa o valor/, transaction.errors.full_messages.to_sentence)
  end

  test "o que sobra do detalhamento fica sem descrição" do
    transaction = build_expense(items_attributes: [ { description: "gasolina", amount: 1000 } ])
    transaction.save!

    assert_equal 1000, transaction.items_total
    assert_equal 2000, transaction.undescribed_amount
  end

  test "detalhamento exato zera a sobra" do
    transaction = build_expense(amount: 100, items_attributes: [
      { description: "a", amount: 60 }, { description: "b", amount: 40 }
    ])
    transaction.save!

    assert_equal 0, transaction.undescribed_amount
  end

  # Regressão: baixar o valor e reduzir os itens na mesma submissão. Se o
  # items_total só fosse recalculado no callback dos itens, o UPDATE do pai
  # gravaria o valor novo com o total antigo e a check constraint estouraria
  # no meio da transação (CHECK no Postgres não é DEFERRABLE).
  test "baixar o valor junto com o detalhamento não viola a constraint" do
    transaction = build_expense(items_attributes: [ { description: "gasolina", amount: 1000 } ])
    transaction.save!
    item = transaction.items.first

    assert_nothing_raised do
      transaction.update!(amount: 1200, items_attributes: [ { id: item.id, amount: 800 } ])
    end

    assert_equal 1200, transaction.reload.amount
    assert_equal 800,  transaction.items_total
    assert_equal 400,  transaction.undescribed_amount
  end

  test "o banco recusa items_total maior que o valor mesmo por fora do model" do
    transaction = build_expense
    transaction.save!

    error = assert_raises(ActiveRecord::StatementInvalid) do
      transaction.update_column(:items_total, 5000)
    end
    assert_match(/transactions_items_within_amount/, error.message)
  end

  test "remover um item devolve o valor para a sobra" do
    transaction = build_expense(items_attributes: [ { description: "gasolina", amount: 1000 } ])
    transaction.save!

    transaction.items.first.destroy

    assert_equal 0,    transaction.reload.items_total
    assert_equal 3000, transaction.undescribed_amount
  end

  test "saída é negativa e entrada é positiva no valor com sinal" do
    saida   = build_expense(amount: 50)
    entrada = @user.transactions.build(kind: "income", description: "Salário", amount: 50,
                                       occurred_on: Date.current, account: @account)

    assert_equal(-50, saida.signed_amount)
    assert_equal 50, entrada.signed_amount
  end

  test "não aceita conta de outro usuário" do
    alheia = users(:two).accounts.create!(name: "Conta alheia", kind: "checking")
    transaction = build_expense(account: alheia)

    assert_not transaction.valid?
    assert_match(/não pertence a este usuário/, transaction.errors.full_messages.to_sentence)
  end

  test "não aceita tag de outro usuário" do
    alheia = users(:two).tags.create!(name: "Tag alheia")
    transaction = build_expense(tag: alheia)

    assert_not transaction.valid?
    assert_match(/não pertence a este usuário/, transaction.errors.full_messages.to_sentence)
  end

  test "valor precisa ser positivo" do
    assert_not build_expense(amount: 0).valid?
    assert_not build_expense(amount: -10).valid?
  end
end
