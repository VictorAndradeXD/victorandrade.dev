# O percentual da renda reservado a uma meta. Gravado sempre em conjunto pelo
# BudgetGoalSet, que é quem garante que a soma não passa de 100%.
class BudgetGoal < ApplicationRecord
  belongs_to :user

  validates :category, inclusion: { in: Budget::CATEGORY_KEYS }, uniqueness: { scope: :user_id }
  validates :percent, numericality: { only_integer: true, in: 0..100 }
end
