class InstallmentPlan < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :tag, optional: true
  has_many :transactions, dependent: :destroy

  enum :kind, Transaction::KINDS.index_by(&:to_sym), validate: true

  validates :description, presence: true
  validates :total_amount, numericality: { greater_than: 0 }
  validates :installments_count, numericality: { in: 2..360 }
  validates :first_due_on, presence: true

  after_create :build_installments!

  # Divide o total em parcelas de centavos exatos; a sobra do arredondamento
  # vai na primeira parcela, então a soma bate com o total sempre.
  def installment_amounts
    base = (total_amount / installments_count).floor(2)
    remainder = total_amount - (base * installments_count)

    Array.new(installments_count) { |i| i.zero? ? base + remainder : base }
  end

  private
    def build_installments!
      installment_amounts.each_with_index do |amount, index|
        transactions.create!(
          user: user, account: account, tag: tag, kind: kind,
          description: "#{description} (#{index + 1}/#{installments_count})",
          amount: amount,
          occurred_on: first_due_on >> index,
          installment_number: index + 1
        )
      end
    end
end
