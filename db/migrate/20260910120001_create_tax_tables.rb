# Tabelas fiscais no banco, e não em constantes no código, porque mudam todo ano
# por decisão de terceiros. Com vigência, um cálculo de competência antiga
# continua usando a tabela da época — refazer 2026 em 2028 tem que dar o mesmo
# número que deu na hora.
class CreateTaxTables < ActiveRecord::Migration[8.1]
  def change
    # Faixas dos Anexos III e V do Simples Nacional.
    create_table :tax_anexo_brackets do |t|
      t.string  :anexo, null: false
      t.decimal :rbt12_from, precision: 14, scale: 2, null: false
      t.decimal :rbt12_to,   precision: 14, scale: 2               # nulo = última faixa
      t.decimal :rate,       precision: 7,  scale: 6, null: false  # 0.155000
      t.decimal :deduction,  precision: 14, scale: 2, null: false, default: 0
      t.date    :valid_from, null: false
      t.date    :valid_to                                          # nulo = ainda vigente

      t.timestamps

      t.index %i[anexo valid_from rbt12_from], name: "index_tax_anexo_brackets_lookup"
    end

    add_check_constraint :tax_anexo_brackets, "anexo IN ('III', 'V')",
                         name: "tax_anexo_brackets_anexo_check"
    add_check_constraint :tax_anexo_brackets, "rate > 0 AND rate < 1",
                         name: "tax_anexo_brackets_rate_range"
    add_check_constraint :tax_anexo_brackets, "deduction >= 0",
                         name: "tax_anexo_brackets_deduction_non_negative"
    add_check_constraint :tax_anexo_brackets, "rbt12_from >= 0",
                         name: "tax_anexo_brackets_from_non_negative"
    add_check_constraint :tax_anexo_brackets, "rbt12_to IS NULL OR rbt12_to > rbt12_from",
                         name: "tax_anexo_brackets_range_order"
    add_check_constraint :tax_anexo_brackets, "valid_to IS NULL OR valid_to >= valid_from",
                         name: "tax_anexo_brackets_validity_order"

    # INSS do contribuinte individual e o piso do pró-labore. Vivem juntos
    # porque mudam na mesma data — a virada do ano — e são usados na mesma conta.
    create_table :tax_inss_rules do |t|
      t.decimal :rate,         precision: 7,  scale: 6, null: false  # 0.110000
      t.decimal :ceiling,      precision: 14, scale: 2, null: false  # teto do salário de contribuição
      t.decimal :minimum_wage, precision: 14, scale: 2, null: false  # piso do pró-labore
      t.date    :valid_from, null: false
      t.date    :valid_to

      t.timestamps

      t.index %i[valid_from], name: "index_tax_inss_rules_on_valid_from"
    end

    add_check_constraint :tax_inss_rules, "rate > 0 AND rate < 1", name: "tax_inss_rules_rate_range"
    add_check_constraint :tax_inss_rules, "ceiling > 0", name: "tax_inss_rules_ceiling_positive"
    add_check_constraint :tax_inss_rules, "minimum_wage > 0", name: "tax_inss_rules_wage_positive"
    add_check_constraint :tax_inss_rules, "valid_to IS NULL OR valid_to >= valid_from",
                         name: "tax_inss_rules_validity_order"

    # Parâmetros do IRRF que não são faixa: dedução por dependente, desconto
    # simplificado e, desde 2026, a isenção até um teto com redução parcial
    # acima dele.
    create_table :tax_irrf_rules do |t|
      t.decimal :dependent_deduction, precision: 14, scale: 2, null: false
      t.decimal :simplified_discount, precision: 14, scale: 2, null: false
      t.decimal :exempt_up_to,        precision: 14, scale: 2   # nulo = sem isenção especial
      t.decimal :phase_out_up_to,     precision: 14, scale: 2   # fim da redução parcial
      t.date    :valid_from, null: false
      t.date    :valid_to

      t.timestamps

      t.index %i[valid_from], name: "index_tax_irrf_rules_on_valid_from"
    end

    add_check_constraint :tax_irrf_rules, "dependent_deduction >= 0",
                         name: "tax_irrf_rules_dependent_non_negative"
    add_check_constraint :tax_irrf_rules, "simplified_discount >= 0",
                         name: "tax_irrf_rules_simplified_non_negative"
    add_check_constraint :tax_irrf_rules,
                         "phase_out_up_to IS NULL OR exempt_up_to IS NULL OR phase_out_up_to >= exempt_up_to",
                         name: "tax_irrf_rules_phase_out_order"
    add_check_constraint :tax_irrf_rules, "valid_to IS NULL OR valid_to >= valid_from",
                         name: "tax_irrf_rules_validity_order"

    # Faixas progressivas do IRRF, presas à regra da mesma vigência.
    create_table :tax_irrf_brackets do |t|
      t.references :tax_irrf_rule, null: false, foreign_key: true
      t.decimal :base_from, precision: 14, scale: 2, null: false
      t.decimal :base_to,   precision: 14, scale: 2               # nulo = última faixa
      t.decimal :rate,      precision: 7,  scale: 6, null: false
      t.decimal :deduction, precision: 14, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :tax_irrf_brackets, "rate >= 0 AND rate < 1", name: "tax_irrf_brackets_rate_range"
    add_check_constraint :tax_irrf_brackets, "deduction >= 0", name: "tax_irrf_brackets_deduction_non_negative"
    add_check_constraint :tax_irrf_brackets, "base_from >= 0", name: "tax_irrf_brackets_from_non_negative"
    add_check_constraint :tax_irrf_brackets, "base_to IS NULL OR base_to > base_from",
                         name: "tax_irrf_brackets_range_order"
  end
end
