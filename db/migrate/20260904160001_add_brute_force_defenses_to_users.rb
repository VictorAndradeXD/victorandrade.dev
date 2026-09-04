class AddBruteForceDefensesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :failed_attempts, :integer, null: false, default: 0
    add_column :users, :locked_until, :datetime
    add_column :users, :last_login_at, :datetime

    add_check_constraint :users, "failed_attempts >= 0", name: "users_failed_attempts_non_negative"
  end
end
