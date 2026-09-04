class Transaction < ApplicationRecord
  KINDS = %w[income expense].freeze

  belongs_to :user
  belongs_to :account
  belongs_to :tag,              optional: true
  belongs_to :recurring_rule,   optional: true
  belongs_to :installment_plan, optional: true

  # `items` é o detalhamento por dentro do lançamento: uma fatura de cartão de
  # R$ 3.000 pode ter um item "gasolina R$ 1.000", sobrando R$ 2.000 sem
  # descrição. A soma dos itens nunca ultrapassa `amount` — validado aqui e
  # garantido no banco pela check constraint `transactions_items_within_amount`.
  has_many :items, class_name: "TransactionItem", dependent: :destroy, inverse_of: :parent
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  enum :kind, KINDS.index_by(&:to_sym), validate: true

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :occurred_on, presence: true
  validate  :account_belongs_to_user
  validate  :tag_belongs_to_user
  validate  :items_within_amount

  # Calculado antes do UPDATE do próprio lançamento. Se ficasse só no callback
  # dos itens, baixar `amount` e reduzir o detalhamento na mesma submissão
  # gravaria o valor novo com o items_total antigo — e a check constraint
  # `transactions_items_within_amount` estouraria no meio da transação
  # (CHECK no Postgres não é DEFERRABLE).
  before_save :assign_items_total

  scope :between,  ->(range) { where(occurred_on: range) }
  scope :recent,   -> { order(occurred_on: :desc, id: :desc) }

  # Colunas qualificadas de propósito: `accounts` também tem `kind`, e qualquer
  # escopo com includes/joins deixaria "kind" ambíguo no Postgres.
  SIGNED_AMOUNT_SQL = <<~SQL.squish.freeze
    CASE WHEN transactions.kind = 'income'
         THEN transactions.amount
         ELSE -transactions.amount END
  SQL

  # Soma tudo do escopo tratando saída como negativo.
  def self.signed_total
    sum(Arel.sql(SIGNED_AMOUNT_SQL)) || 0
  end

  # Positivo para entrada, negativo para saída.
  def signed_amount = expense? ? -amount : amount

  # O que sobrou do total sem detalhamento. `amount` é nil num lançamento
  # ainda não preenchido, e o formulário chama isto antes de qualquer digitação.
  def undescribed_amount = (amount || 0) - (items_total || 0)

  def recalculate_items_total!
    update_column(:items_total, TransactionItem.where(transaction_id: id).sum(:amount))
  end

  private
    def assign_items_total
      self.items_total = current_items_total
    end

    def current_items_total
      items.reject(&:marked_for_destruction?).sum { |item| item.amount || 0 }
    end

    def account_belongs_to_user
      return if account.blank? || user_id.blank?
      errors.add(:account, "não pertence a este usuário") if account.user_id != user_id
    end

    def tag_belongs_to_user
      return if tag.blank? || user_id.blank?
      errors.add(:tag, "não pertence a este usuário") if tag.user_id != user_id
    end

    def items_within_amount
      return if amount.blank?

      total = current_items_total
      return if total <= amount

      errors.add(:base, "o detalhamento (#{total}) ultrapassa o valor do lançamento (#{amount})")
    end
end
