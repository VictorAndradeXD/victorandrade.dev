class CreateRecurringRules < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_rules do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :tag,     null: true,  foreign_key: true
      t.string  :kind, null: false
      t.string  :description, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.string  :frequency, null: false
      t.integer :day_of_month
      t.date    :starts_on, null: false
      t.date    :ends_on
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_check_constraint :recurring_rules, "kind IN ('income', 'expense')", name: "recurring_rules_kind_check"
    add_check_constraint :recurring_rules, "frequency IN ('weekly', 'monthly', 'yearly')", name: "recurring_rules_frequency_check"
    add_check_constraint :recurring_rules, "amount > 0", name: "recurring_rules_amount_positive"
    add_check_constraint :recurring_rules, "day_of_month IS NULL OR (day_of_month BETWEEN 1 AND 31)", name: "recurring_rules_day_of_month_range"
    add_check_constraint :recurring_rules, "ends_on IS NULL OR ends_on >= starts_on", name: "recurring_rules_period_order"
  end
end
