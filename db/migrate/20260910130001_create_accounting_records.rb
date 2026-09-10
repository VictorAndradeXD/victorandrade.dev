# Cadastro do módulo contábil: as empresas da carteira, seus sócios, e a receita
# e o pró-labore mês a mês que alimentam o fator R.
#
# Sem escopo por usuário, ao contrário do Denfis: lá dois usuários têm finanças
# separadas, aqui todo mundo com acesso ao módulo trabalha sobre a MESMA
# carteira de clientes. Escopar por usuário faria a contadora e o dono verem
# empresas diferentes, que é o oposto do que se quer.
class CreateAccountingRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :accounting_companies do |t|
      t.string  :name, null: false
      t.string  :cnpj, null: false                       # só dígitos, sem máscara
      t.date    :started_on, null: false                 # início de atividade
      t.boolean :fator_r_eligible, null: false, default: true
      t.boolean :archived, null: false, default: false

      t.timestamps

      t.index :cnpj, unique: true
    end

    add_check_constraint :accounting_companies, "cnpj ~ '^[0-9]{14}$'",
                         name: "accounting_companies_cnpj_digits"

    create_table :accounting_partners do |t|
      t.references :company, null: false, foreign_key: { to_table: :accounting_companies }
      t.string  :name, null: false
      t.string  :cpf, null: false
      t.integer :dependents_count, null: false, default: 0

      t.timestamps

      t.index %i[company_id cpf], unique: true
    end

    add_check_constraint :accounting_partners, "cpf ~ '^[0-9]{11}$'",
                         name: "accounting_partners_cpf_digits"
    add_check_constraint :accounting_partners, "dependents_count >= 0",
                         name: "accounting_partners_dependents_non_negative"

    # Uma linha por empresa por mês. `month` é sempre o dia 1 — competência é
    # mês, não data, e guardar o dia 1 deixa a comparação por intervalo simples.
    create_table :accounting_competencias do |t|
      t.references :company, null: false, foreign_key: { to_table: :accounting_companies }
      t.date    :month, null: false
      t.decimal :gross_revenue, precision: 14, scale: 2, null: false, default: 0

      t.timestamps

      t.index %i[company_id month], unique: true
    end

    add_check_constraint :accounting_competencias, "gross_revenue >= 0",
                         name: "accounting_competencias_revenue_non_negative"
    add_check_constraint :accounting_competencias, "EXTRACT(DAY FROM month) = 1",
                         name: "accounting_competencias_month_is_first_day"

    # O pró-labore de um sócio numa competência. INSS e IRRF ficam gravados, e
    # não recalculados na leitura: a tabela pode mudar depois, e o que foi pago
    # foi pago.
    create_table :accounting_prolabores do |t|
      t.references :competencia, null: false, foreign_key: { to_table: :accounting_competencias }
      t.references :partner, null: false, foreign_key: { to_table: :accounting_partners }
      t.decimal :gross, precision: 14, scale: 2, null: false
      t.decimal :inss,  precision: 14, scale: 2, null: false, default: 0
      t.decimal :irrf,  precision: 14, scale: 2, null: false, default: 0

      t.timestamps

      t.index %i[competencia_id partner_id], unique: true
    end

    add_check_constraint :accounting_prolabores, "gross > 0", name: "accounting_prolabores_gross_positive"
    add_check_constraint :accounting_prolabores, "inss >= 0 AND irrf >= 0",
                         name: "accounting_prolabores_taxes_non_negative"
    add_check_constraint :accounting_prolabores, "inss + irrf <= gross",
                         name: "accounting_prolabores_taxes_within_gross"
  end
end
