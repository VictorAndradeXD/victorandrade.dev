# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_10_130001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounting_companies", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.string "cnpj", null: false
    t.datetime "created_at", null: false
    t.boolean "fator_r_eligible", default: true, null: false
    t.string "name", null: false
    t.date "started_on", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_accounting_companies_on_cnpj", unique: true
    t.check_constraint "cnpj::text ~ '^[0-9]{14}$'::text", name: "accounting_companies_cnpj_digits"
  end

  create_table "accounting_competencias", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.decimal "gross_revenue", precision: 14, scale: 2, default: "0.0", null: false
    t.date "month", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "month"], name: "index_accounting_competencias_on_company_id_and_month", unique: true
    t.index ["company_id"], name: "index_accounting_competencias_on_company_id"
    t.check_constraint "EXTRACT(day FROM month) = 1::numeric", name: "accounting_competencias_month_is_first_day"
    t.check_constraint "gross_revenue >= 0::numeric", name: "accounting_competencias_revenue_non_negative"
  end

  create_table "accounting_partners", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "cpf", null: false
    t.datetime "created_at", null: false
    t.integer "dependents_count", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "cpf"], name: "index_accounting_partners_on_company_id_and_cpf", unique: true
    t.index ["company_id"], name: "index_accounting_partners_on_company_id"
    t.check_constraint "cpf::text ~ '^[0-9]{11}$'::text", name: "accounting_partners_cpf_digits"
    t.check_constraint "dependents_count >= 0", name: "accounting_partners_dependents_non_negative"
  end

  create_table "accounting_prolabores", force: :cascade do |t|
    t.bigint "competencia_id", null: false
    t.datetime "created_at", null: false
    t.decimal "gross", precision: 14, scale: 2, null: false
    t.decimal "inss", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "irrf", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "partner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["competencia_id", "partner_id"], name: "index_accounting_prolabores_on_competencia_id_and_partner_id", unique: true
    t.index ["competencia_id"], name: "index_accounting_prolabores_on_competencia_id"
    t.index ["partner_id"], name: "index_accounting_prolabores_on_partner_id"
    t.check_constraint "(inss + irrf) <= gross", name: "accounting_prolabores_taxes_within_gross"
    t.check_constraint "gross > 0::numeric", name: "accounting_prolabores_gross_positive"
    t.check_constraint "inss >= 0::numeric AND irrf >= 0::numeric", name: "accounting_prolabores_taxes_non_negative"
  end

  create_table "accounts", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.decimal "initial_balance", precision: 14, scale: 2, default: "0.0", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_accounts_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
    t.check_constraint "kind::text = ANY (ARRAY['checking'::character varying::text, 'savings'::character varying::text, 'wallet'::character varying::text, 'credit_card'::character varying::text])", name: "accounts_kind_check"
  end

  create_table "installment_plans", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.date "first_due_on", null: false
    t.integer "installments_count", null: false
    t.string "kind", null: false
    t.bigint "tag_id"
    t.decimal "total_amount", precision: 14, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_installment_plans_on_account_id"
    t.index ["tag_id"], name: "index_installment_plans_on_tag_id"
    t.index ["user_id"], name: "index_installment_plans_on_user_id"
    t.check_constraint "installments_count >= 2 AND installments_count <= 360", name: "installment_plans_count_range"
    t.check_constraint "kind::text = ANY (ARRAY['income'::character varying::text, 'expense'::character varying::text])", name: "installment_plans_kind_check"
    t.check_constraint "total_amount > 0::numeric", name: "installment_plans_total_positive"
  end

  create_table "recurring_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "day_of_month"
    t.string "description", null: false
    t.date "ends_on"
    t.string "frequency", null: false
    t.string "kind", null: false
    t.date "starts_on", null: false
    t.bigint "tag_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_recurring_rules_on_account_id"
    t.index ["tag_id"], name: "index_recurring_rules_on_tag_id"
    t.index ["user_id"], name: "index_recurring_rules_on_user_id"
    t.check_constraint "amount > 0::numeric", name: "recurring_rules_amount_positive"
    t.check_constraint "day_of_month IS NULL OR day_of_month >= 1 AND day_of_month <= 31", name: "recurring_rules_day_of_month_range"
    t.check_constraint "ends_on IS NULL OR ends_on >= starts_on", name: "recurring_rules_period_order"
    t.check_constraint "frequency::text = ANY (ARRAY['weekly'::character varying::text, 'monthly'::character varying::text, 'yearly'::character varying::text])", name: "recurring_rules_frequency_check"
    t.check_constraint "kind::text = ANY (ARRAY['income'::character varying::text, 'expense'::character varying::text])", name: "recurring_rules_kind_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", default: "#6366f1", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "tax_anexo_brackets", force: :cascade do |t|
    t.string "anexo", null: false
    t.datetime "created_at", null: false
    t.decimal "deduction", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "rate", precision: 7, scale: 6, null: false
    t.decimal "rbt12_from", precision: 14, scale: 2, null: false
    t.decimal "rbt12_to", precision: 14, scale: 2
    t.datetime "updated_at", null: false
    t.date "valid_from", null: false
    t.date "valid_to"
    t.index ["anexo", "valid_from", "rbt12_from"], name: "index_tax_anexo_brackets_lookup"
    t.check_constraint "anexo::text = ANY (ARRAY['III'::character varying, 'V'::character varying]::text[])", name: "tax_anexo_brackets_anexo_check"
    t.check_constraint "deduction >= 0::numeric", name: "tax_anexo_brackets_deduction_non_negative"
    t.check_constraint "rate > 0::numeric AND rate < 1::numeric", name: "tax_anexo_brackets_rate_range"
    t.check_constraint "rbt12_from >= 0::numeric", name: "tax_anexo_brackets_from_non_negative"
    t.check_constraint "rbt12_to IS NULL OR rbt12_to > rbt12_from", name: "tax_anexo_brackets_range_order"
    t.check_constraint "valid_to IS NULL OR valid_to >= valid_from", name: "tax_anexo_brackets_validity_order"
  end

  create_table "tax_inss_rules", force: :cascade do |t|
    t.decimal "ceiling", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "minimum_wage", precision: 14, scale: 2, null: false
    t.decimal "rate", precision: 7, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.date "valid_from", null: false
    t.date "valid_to"
    t.index ["valid_from"], name: "index_tax_inss_rules_on_valid_from"
    t.check_constraint "ceiling > 0::numeric", name: "tax_inss_rules_ceiling_positive"
    t.check_constraint "minimum_wage > 0::numeric", name: "tax_inss_rules_wage_positive"
    t.check_constraint "rate > 0::numeric AND rate < 1::numeric", name: "tax_inss_rules_rate_range"
    t.check_constraint "valid_to IS NULL OR valid_to >= valid_from", name: "tax_inss_rules_validity_order"
  end

  create_table "tax_irrf_brackets", force: :cascade do |t|
    t.decimal "base_from", precision: 14, scale: 2, null: false
    t.decimal "base_to", precision: 14, scale: 2
    t.datetime "created_at", null: false
    t.decimal "deduction", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "rate", precision: 7, scale: 6, null: false
    t.bigint "tax_irrf_rule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_irrf_rule_id"], name: "index_tax_irrf_brackets_on_tax_irrf_rule_id"
    t.check_constraint "base_from >= 0::numeric", name: "tax_irrf_brackets_from_non_negative"
    t.check_constraint "base_to IS NULL OR base_to > base_from", name: "tax_irrf_brackets_range_order"
    t.check_constraint "deduction >= 0::numeric", name: "tax_irrf_brackets_deduction_non_negative"
    t.check_constraint "rate >= 0::numeric AND rate < 1::numeric", name: "tax_irrf_brackets_rate_range"
  end

  create_table "tax_irrf_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "dependent_deduction", precision: 14, scale: 2, null: false
    t.decimal "exempt_up_to", precision: 14, scale: 2
    t.decimal "phase_out_up_to", precision: 14, scale: 2
    t.decimal "simplified_discount", precision: 14, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.date "valid_from", null: false
    t.date "valid_to"
    t.index ["valid_from"], name: "index_tax_irrf_rules_on_valid_from"
    t.check_constraint "dependent_deduction >= 0::numeric", name: "tax_irrf_rules_dependent_non_negative"
    t.check_constraint "phase_out_up_to IS NULL OR exempt_up_to IS NULL OR phase_out_up_to >= exempt_up_to", name: "tax_irrf_rules_phase_out_order"
    t.check_constraint "simplified_discount >= 0::numeric", name: "tax_irrf_rules_simplified_non_negative"
    t.check_constraint "valid_to IS NULL OR valid_to >= valid_from", name: "tax_irrf_rules_validity_order"
  end

  create_table "transaction_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_id"], name: "index_transaction_items_on_transaction_id"
    t.check_constraint "amount > 0::numeric", name: "transaction_items_amount_positive"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "installment_number"
    t.bigint "installment_plan_id"
    t.decimal "items_total", precision: 14, scale: 2, default: "0.0", null: false
    t.string "kind", null: false
    t.date "occurred_on", null: false
    t.bigint "recurring_rule_id"
    t.bigint "tag_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["installment_plan_id"], name: "index_transactions_on_installment_plan_id"
    t.index ["recurring_rule_id"], name: "index_transactions_on_recurring_rule_id"
    t.index ["tag_id"], name: "index_transactions_on_tag_id"
    t.index ["user_id", "occurred_on"], name: "index_transactions_on_user_id_and_occurred_on"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.check_constraint "(installment_plan_id IS NULL) = (installment_number IS NULL)", name: "transactions_installment_pairing"
    t.check_constraint "amount > 0::numeric", name: "transactions_amount_positive"
    t.check_constraint "items_total <= amount", name: "transactions_items_within_amount"
    t.check_constraint "items_total >= 0::numeric", name: "transactions_items_total_non_negative"
    t.check_constraint "kind::text = ANY (ARRAY['income'::character varying::text, 'expense'::character varying::text])", name: "transactions_kind_check"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "accounting_access", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "denfis_access", default: true, null: false
    t.string "email_address", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_login_at"
    t.datetime "locked_until"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "denfis_access OR accounting_access", name: "users_has_at_least_one_module"
    t.check_constraint "failed_attempts >= 0", name: "users_failed_attempts_non_negative"
  end

  add_foreign_key "accounting_competencias", "accounting_companies", column: "company_id"
  add_foreign_key "accounting_partners", "accounting_companies", column: "company_id"
  add_foreign_key "accounting_prolabores", "accounting_competencias", column: "competencia_id"
  add_foreign_key "accounting_prolabores", "accounting_partners", column: "partner_id"
  add_foreign_key "accounts", "users"
  add_foreign_key "installment_plans", "accounts"
  add_foreign_key "installment_plans", "tags"
  add_foreign_key "installment_plans", "users"
  add_foreign_key "recurring_rules", "accounts"
  add_foreign_key "recurring_rules", "tags"
  add_foreign_key "recurring_rules", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "tax_irrf_brackets", "tax_irrf_rules"
  add_foreign_key "transaction_items", "transactions"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "installment_plans"
  add_foreign_key "transactions", "recurring_rules"
  add_foreign_key "transactions", "tags"
  add_foreign_key "transactions", "users"
end
