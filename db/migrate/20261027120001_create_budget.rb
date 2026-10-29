class CreateBudget < ActiveRecord::Migration[8.1]
  # Lista fixa de propósito, e não Budget::CATEGORIES: migration que lê
  # constante da aplicação muda de significado quando a constante muda.
  CATEGORIES = %w[fixed_costs comfort goals pleasures financial_freedom knowledge].freeze
  CATEGORY_CHECK = "budget_category IS NULL OR budget_category IN (#{CATEGORIES.map { "'#{it}'" }.join(', ')})".freeze

  def change
    # Quanto da renda vai para cada meta. Uma linha por meta; a soma não passar
    # de 100% é validada no BudgetGoal.save_for, que grava todas juntas.
    create_table :budget_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :category, null: false
      t.integer :percent,  null: false

      t.timestamps
    end
    add_index :budget_goals, %i[user_id category], unique: true
    add_check_constraint :budget_goals, "percent BETWEEN 0 AND 100", name: "budget_goals_percent_range"
    add_check_constraint :budget_goals, CATEGORY_CHECK.sub("budget_category IS NULL OR budget_category", "category"),
                         name: "budget_goals_category_check"

    # Renda ajustada à mão para um mês. Sem linha, vale a soma das receitas.
    create_table :budget_incomes do |t|
      t.references :user, null: false, foreign_key: true
      t.date    :month, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false

      t.timestamps
    end
    add_index :budget_incomes, %i[user_id month], unique: true
    add_check_constraint :budget_incomes, "amount >= 0", name: "budget_incomes_amount_non_negative"
    add_check_constraint :budget_incomes, "EXTRACT(day FROM month) = 1", name: "budget_incomes_month_is_first_day"

    # Auto preenchimento: gastos que se repetem todo mês, por meta.
    create_table :budget_presets do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :category, null: false
      t.string  :description, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false

      t.timestamps
    end
    # O preenchimento casa pelo nome; dois modelos de mesmo nome seriam ambíguos.
    add_index :budget_presets, "user_id, lower(description)", unique: true, name: "index_budget_presets_on_user_and_description"
    add_check_constraint :budget_presets, "amount > 0", name: "budget_presets_amount_positive"
    add_check_constraint :budget_presets, CATEGORY_CHECK.sub("budget_category IS NULL OR budget_category", "category"),
                         name: "budget_presets_category_check"

    # A meta viaja junto com o lançamento, e as regras que geram lançamentos
    # carregam a delas para as parcelas e recorrências saírem já classificadas.
    %i[transactions recurring_rules installment_plans].each do |table|
      add_column table, :budget_category, :string
      add_check_constraint table, CATEGORY_CHECK, name: "#{table}_budget_category_check"
    end
  end
end
