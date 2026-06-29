class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :list, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.datetime :due_on
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
    add_index :cards, [:list_id, :position]
  end
end
