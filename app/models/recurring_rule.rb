class RecurringRule < ApplicationRecord
  KINDS       = Transaction::KINDS
  FREQUENCIES = %w[weekly monthly yearly].freeze

  belongs_to :user
  belongs_to :account
  belongs_to :tag, optional: true
  has_many :transactions, dependent: :nullify

  enum :kind,      KINDS.index_by(&:to_sym),       validate: true
  enum :frequency, FREQUENCIES.index_by(&:to_sym), validate: true, prefix: true

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :starts_on, presence: true
  validates :day_of_month, numericality: { in: 1..31 }, allow_nil: true
  validate  :ends_on_after_starts_on

  scope :active, -> { where(active: true) }

  # Datas em que a regra cai dentro do intervalo pedido.
  def occurrences_in(range)
    last = [ range.end, ends_on ].compact.min
    return [] if last.nil? || last < starts_on

    dates = []
    cursor = starts_on
    while cursor <= last
      dates << cursor if cursor >= range.begin
      cursor = advance_from(cursor)
    end
    dates
  end

  # Cria os lançamentos que faltam no intervalo. Idempotente: reexecutar não
  # duplica nada, porque a data já materializada é pulada.
  def materialize!(range)
    existing = transactions.where(occurred_on: range).pluck(:occurred_on).to_set

    occurrences_in(range).reject { |date| existing.include?(date) }.map do |date|
      transactions.create!(
        user: user, account: account, tag: tag, kind: kind,
        description: description, amount: amount, occurred_on: date
      )
    end
  end

  private
    def advance_from(date)
      case frequency
      when "weekly"  then date + 1.week
      when "yearly"  then date + 1.year
      when "monthly" then next_month_from(date)
      end
    end

    # Respeita `day_of_month` sem estourar em meses curtos: dia 31 vira 28/29
    # em fevereiro em vez de pular o mês.
    def next_month_from(date)
      target = date.next_month
      return target if day_of_month.blank?

      Date.new(target.year, target.month, [ day_of_month, target.end_of_month.day ].min)
    end

    def ends_on_after_starts_on
      return if ends_on.blank? || starts_on.blank?
      errors.add(:ends_on, "não pode ser antes do início") if ends_on < starts_on
    end
end
