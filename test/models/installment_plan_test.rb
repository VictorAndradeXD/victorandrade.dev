require "test_helper"

class InstallmentPlanTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @account = @user.accounts.create!(name: "Cartão", kind: "credit_card")
  end

  def plan(total:, count:, first_due_on: Date.new(2026, 5, 15))
    @user.installment_plans.create!(
      kind: "expense", description: "Notebook", total_amount: total,
      installments_count: count, first_due_on: first_due_on, account: @account
    )
  end

  test "a soma das parcelas bate com o total mesmo quando não divide exato" do
    [ [ 1000, 3 ], [ 2847.33, 12 ], [ 100, 7 ], [ 0.05, 4 ] ].each do |total, count|
      p = plan(total: total, count: count)

      assert_equal total.to_d, p.transactions.sum(:amount), "#{total} em #{count}x"
      assert_equal count, p.transactions.count
    end
  end

  test "a sobra do arredondamento vai na primeira parcela" do
    p = plan(total: 1000, count: 3)
    valores = p.transactions.order(:installment_number).pluck(:amount)

    assert_equal [ 333.34, 333.33, 333.33 ].map(&:to_d), valores
  end

  test "as parcelas caem de mês em mês a partir da primeira" do
    p = plan(total: 300, count: 3, first_due_on: Date.new(2026, 1, 31))

    assert_equal [ Date.new(2026, 1, 31), Date.new(2026, 2, 28), Date.new(2026, 3, 31) ],
                 p.transactions.order(:installment_number).pluck(:occurred_on)
  end

  test "cada parcela sabe a própria posição" do
    p = plan(total: 300, count: 3)

    assert_equal [ 1, 2, 3 ], p.transactions.order(:installment_number).pluck(:installment_number)
    assert_equal "Notebook (2/3)", p.transactions.find_by(installment_number: 2).description
  end

  test "apagar o parcelamento leva as parcelas junto" do
    p = plan(total: 300, count: 3)

    assert_difference -> { Transaction.count }, -3 do
      p.destroy
    end
  end

  test "exige pelo menos duas parcelas" do
    invalido = @user.installment_plans.build(
      kind: "expense", description: "x", total_amount: 100,
      installments_count: 1, first_due_on: Date.current, account: @account
    )

    assert_not invalido.valid?
  end
end
