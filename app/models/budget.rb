# Orçamento doméstico de um mês: quanto da renda cada meta pode levar e quanto
# dela já foi gasto. Não é tabela — junta as metas do usuário (BudgetGoal), a
# renda do mês (BudgetIncome ou a soma das receitas) e as despesas lançadas.
class Budget
  Category = Data.define(:key, :name, :color, :default_percent)

  # As seis metas são fixas, como na planilha que serviu de referência. As
  # cores ficam aqui e não no CSS porque o donut é desenhado em SVG inline.
  CATEGORIES = [
    Category.new("fixed_costs",       "Custos fixos",         "#7cb8f5", 30),
    Category.new("comfort",           "Conforto",             "#86e3c3", 15),
    Category.new("goals",             "Metas",                "#f2df5e", 15),
    Category.new("pleasures",         "Prazeres",             "#eea6e6", 10),
    Category.new("financial_freedom", "Liberdade financeira", "#8191f2", 25),
    Category.new("knowledge",         "Conhecimento",         "#f0a050",  5)
  ].freeze

  CATEGORY_KEYS = CATEGORIES.map(&:key).freeze
  UNASSIGNED_COLOR = "#4b5563"

  def self.category(key) = CATEGORIES.find { it.key == key }
  def self.category_options = CATEGORIES.map { [ it.name, it.key ] }
  def self.default_percents = CATEGORIES.to_h { [ it.key, it.default_percent ] }

  # Uma linha do resumo. `used` é nil quando a meta é 0% ou a renda é zero:
  # não existe "quanto do previsto" sem previsto.
  Row = Data.define(:category, :percent, :spent, :planned) do
    def used = planned.positive? ? spent / planned : nil
    def over? = used.present? && used > 1
  end

  attr_reader :user, :month

  def initialize(user, month)
    @user  = user
    @month = month.beginning_of_month
  end

  def range = month.all_month

  def income_override = @income_override ||= user.budget_incomes.find_by(month: month)
  def recorded_income = @recorded_income ||= user.transactions.between(range).income.sum(:amount)
  def income = income_override&.amount || recorded_income
  def income_adjusted? = income_override.present?

  def percents = @percents ||= BudgetGoalSet.new(user).percents
  def allocated_percent = percents.values.sum

  def rows
    @rows ||= CATEGORIES.map do |category|
      percent = percents.fetch(category.key)
      Row.new(category, percent, spent_by_category.fetch(category.key, 0).to_d, planned_for(percent))
    end
  end

  # Despesa do mês que ainda não foi ligada a meta nenhuma. Aparece no resumo
  # para o total gasto bater com o dashboard em vez de sumir calado.
  def unassigned_spent = spent_by_category.fetch(nil, 0).to_d

  def total_spent   = rows.sum(&:spent) + unassigned_spent
  def total_planned = rows.sum(&:planned)
  def total_used    = total_planned.positive? ? total_spent / total_planned : nil

  private
    def spent_by_category
      @spent_by_category ||= user.transactions.between(range).expense.group(:budget_category).sum(:amount)
    end

    def planned_for(percent) = (income * percent / 100).round(2)
end
