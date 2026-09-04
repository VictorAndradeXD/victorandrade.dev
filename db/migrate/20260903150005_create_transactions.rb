class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :tag,     null: true,  foreign_key: true
      t.string  :kind, null: false
      t.string  :description, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.date    :occurred_on, null: false

      # Soma cacheada dos itens de detalhamento. Mantida pelo TransactionItem
      # e guardada por check constraint: o detalhe nunca ultrapassa o total.
      t.decimal :items_total, precision: 14, scale: 2, null: false, default: 0

      t.references :recurring_rule,   null: true, foreign_key: true
      t.references :installment_plan, null: true, foreign_key: true
      t.integer    :installment_number

      t.timestamps
    end

    add_index :transactions, [ :user_id, :occurred_on ]

    add_check_constraint :transactions, "kind IN ('income', 'expense')", name: "transactions_kind_check"
    add_check_constraint :transactions, "amount > 0", name: "transactions_amount_positive"
    add_check_constraint :transactions, "items_total >= 0", name: "transactions_items_total_non_negative"
    add_check_constraint :transactions, "items_total <= amount", name: "transactions_items_within_amount"
    add_check_constraint :transactions,
      "(installment_plan_id IS NULL) = (installment_number IS NULL)",
      name: "transactions_installment_pairing"
  end
end
