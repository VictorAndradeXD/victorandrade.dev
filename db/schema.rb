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

ActiveRecord::Schema[8.1].define(version: 2026_09_04_160001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_login_at"
    t.datetime "locked_until"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "failed_attempts >= 0", name: "users_failed_attempts_non_negative"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "installment_plans", "accounts"
  add_foreign_key "installment_plans", "tags"
  add_foreign_key "installment_plans", "users"
  add_foreign_key "recurring_rules", "accounts"
  add_foreign_key "recurring_rules", "tags"
  add_foreign_key "recurring_rules", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "transaction_items", "transactions"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "installment_plans"
  add_foreign_key "transactions", "recurring_rules"
  add_foreign_key "transactions", "tags"
  add_foreign_key "transactions", "users"
end
