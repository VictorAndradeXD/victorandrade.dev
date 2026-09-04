class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :kind, null: false
      t.decimal :initial_balance, precision: 14, scale: 2, null: false, default: 0
      t.boolean :archived, null: false, default: false

      t.timestamps
    end

    add_index :accounts, [ :user_id, :name ], unique: true
    add_check_constraint :accounts, "kind IN ('checking', 'savings', 'wallet', 'credit_card')", name: "accounts_kind_check"
  end
end
