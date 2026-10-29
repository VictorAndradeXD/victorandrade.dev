# As seis metas editadas juntas, como na tela de sliders. Existe porque a regra
# que importa — a soma não passar de 100% — não cabe em nenhuma linha sozinha:
# subir uma meta só é válido se outra descer junto.
class BudgetGoalSet
  include ActiveModel::Model

  MAX_TOTAL = 100

  attr_reader :user, :percents

  validate :each_percent_in_range
  validate :total_within_income

  # Sem `percents`, carrega o que está salvo — e o padrão de cada meta que o
  # usuário ainda não tocou.
  def initialize(user, percents = nil)
    @user = user
    @percents = percents ? normalize(percents) : saved_percents
  end

  def total = percents.values.sum
  def excess = [ total - MAX_TOTAL, 0 ].max

  def save
    return false unless valid?

    BudgetGoal.transaction do
      percents.each do |category, percent|
        user.budget_goals.find_or_initialize_by(category: category).update!(percent: percent)
      end
    end
    true
  end

  private
    def saved_percents
      Budget.default_percents.merge(user.budget_goals.pluck(:category, :percent).to_h)
    end

    # Só as chaves conhecidas, na ordem do orçamento. Meta que não veio no
    # formulário fica com o valor salvo em vez de virar zero.
    def normalize(raw)
      raw = raw.to_h.stringify_keys
      saved = saved_percents

      Budget::CATEGORY_KEYS.index_with do |key|
        raw.key?(key) ? Integer(raw[key].to_s, exception: false) : saved.fetch(key)
      end
    end

    def each_percent_in_range
      percents.each do |key, percent|
        next if percent.is_a?(Integer) && percent.between?(0, MAX_TOTAL)

        errors.add(:base, "#{Budget.category(key).name} precisa ficar entre 0% e 100%")
      end
    end

    def total_within_income
      return if errors.any? || excess.zero?

      errors.add(:base, "a soma das metas passou de 100% em #{excess} pontos. " \
                        "Reduza outras metas para não comprometer o orçamento.")
    end
end
