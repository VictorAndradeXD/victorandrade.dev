class CreateInstallmentPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :installment_plans do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :tag,     null: true,  foreign_key: true
      t.string  :kind, null: false
      t.string  :description, null: false
      t.decimal :total_amount, precision: 14, scale: 2, null: false
      t.integer :installments_count, null: false
      t.date    :first_due_on, null: false

      t.timestamps
    end

    add_check_constraint :installment_plans, "kind IN ('income', 'expense')", name: "installment_plans_kind_check"
    add_check_constraint :installment_plans, "total_amount > 0", name: "installment_plans_total_positive"
    add_check_constraint :installment_plans, "installments_count BETWEEN 2 AND 360", name: "installment_plans_count_range"
  end
end
