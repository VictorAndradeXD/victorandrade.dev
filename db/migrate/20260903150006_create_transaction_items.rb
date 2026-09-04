class CreateTransactionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_items do |t|
      t.references :transaction, null: false, foreign_key: true
      t.string  :description, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false

      t.timestamps
    end

    add_check_constraint :transaction_items, "amount > 0", name: "transaction_items_amount_positive"
  end
end
