class TransactionItem < ApplicationRecord
  # Nomeado `parent` de propósito: uma associação chamada `transaction`
  # sobrescreveria ActiveRecord::Transactions#transaction e quebraria
  # coisas como `record.with_lock`.
  belongs_to :parent, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :items

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }

  after_save    :sync_parent_items_total
  after_destroy :sync_parent_items_total

  private
    def sync_parent_items_total
      parent.recalculate_items_total!
    end
end
