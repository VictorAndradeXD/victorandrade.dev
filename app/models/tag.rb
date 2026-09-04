class Tag < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, format: { with: /\A#\h{6}\z/, message: "deve ser um hex tipo #6366f1" }
end
