# Recorrências saíram do Denfis: o auto preenchimento do orçamento cobre o mesmo
# caso (o gasto que se repete todo mês) e ter os dois confundia. Os lançamentos
# que uma regra já gerou continuam existindo; só perdem o vínculo com ela.
#
# O bloco do drop_table repete a definição só para a migration ser reversível —
# um rollback recria a tabela vazia, não devolve as regras apagadas.
class DropRecurringRules < ActiveRecord::Migration[8.1]
  def change
    remove_reference :transactions, :recurring_rule, foreign_key: true, index: true

    drop_table :recurring_rules do |t|
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
      t.string  :budget_category

      t.timestamps
    end
  end
end
