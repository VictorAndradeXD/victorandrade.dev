class Account < ApplicationRecord
  KINDS = %w[checking savings wallet credit_card].freeze

  belongs_to :user
  has_many :transactions, dependent: :restrict_with_error

  enum :kind, KINDS.index_by(&:to_sym), validate: true

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :initial_balance, numericality: true

  scope :active, -> { where(archived: false) }

  # Saldo = aporte inicial + entradas - saídas.
  def balance(up_to: nil)
    scope = transactions
    scope = scope.where(occurred_on: ..up_to) if up_to
    initial_balance + scope.signed_total
  end
end
