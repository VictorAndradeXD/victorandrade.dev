require "test_helper"

class RecurringRuleTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @account = @user.accounts.create!(name: "Conta", kind: "checking")
  end

  def rule(**attrs)
    @user.recurring_rules.create!({
      kind: "expense", description: "Aluguel", amount: 2500, frequency: "monthly",
      starts_on: Date.new(2026, 1, 31), day_of_month: 31, account: @account
    }.merge(attrs))
  end

  # Fevereiro não tem dia 31: a regra tem que cair no último dia, não sumir.
  test "mensal no dia 31 não pula os meses curtos" do
    datas = rule.occurrences_in(Date.new(2026, 1, 1)..Date.new(2026, 4, 30))

    assert_equal [ Date.new(2026, 1, 31), Date.new(2026, 2, 28),
                   Date.new(2026, 3, 31), Date.new(2026, 4, 30) ], datas
  end

  test "materializar duas vezes não duplica lançamento" do
    r = rule
    periodo = Date.new(2026, 1, 1)..Date.new(2026, 3, 31)

    assert_equal 3, r.materialize!(periodo).size
    assert_equal 0, r.materialize!(periodo).size
    assert_equal 3, r.transactions.count
  end

  test "não gera nada depois da data de término" do
    r = rule(ends_on: Date.new(2026, 2, 28))
    datas = r.occurrences_in(Date.new(2026, 1, 1)..Date.new(2026, 6, 30))

    assert_equal [ Date.new(2026, 1, 31), Date.new(2026, 2, 28) ], datas
  end

  test "não gera nada antes do início" do
    r = rule(starts_on: Date.new(2026, 3, 1), day_of_month: 1)

    assert_empty r.occurrences_in(Date.new(2026, 1, 1)..Date.new(2026, 2, 28))
  end

  test "semanal anda de sete em sete dias" do
    r = rule(frequency: "weekly", day_of_month: nil, starts_on: Date.new(2026, 3, 2))
    datas = r.occurrences_in(Date.new(2026, 3, 1)..Date.new(2026, 3, 23))

    assert_equal [ 2, 9, 16, 23 ].map { |d| Date.new(2026, 3, d) }, datas
  end

  test "anual repete na mesma data" do
    r = rule(frequency: "yearly", day_of_month: nil, starts_on: Date.new(2026, 1, 10))
    datas = r.occurrences_in(Date.new(2026, 1, 1)..Date.new(2028, 12, 31))

    assert_equal [ 2026, 2027, 2028 ].map { |y| Date.new(y, 1, 10) }, datas
  end

  test "os lançamentos gerados herdam conta, tag e tipo da regra" do
    tag = @user.tags.create!(name: "Moradia")
    r = rule(tag: tag)
    lancamento = r.materialize!(Date.new(2026, 1, 1)..Date.new(2026, 1, 31)).first

    assert_equal @account, lancamento.account
    assert_equal tag,      lancamento.tag
    assert_equal "expense", lancamento.kind
    assert_equal 2500, lancamento.amount
  end

  test "término não pode ser antes do início" do
    invalida = @user.recurring_rules.build(
      kind: "expense", description: "x", amount: 10, frequency: "monthly",
      starts_on: Date.new(2026, 5, 1), ends_on: Date.new(2026, 4, 1), account: @account
    )

    assert_not invalida.valid?
  end
end
