class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "#6366f1"

      t.timestamps
    end

    add_index :tags, [ :user_id, :name ], unique: true
  end
end
