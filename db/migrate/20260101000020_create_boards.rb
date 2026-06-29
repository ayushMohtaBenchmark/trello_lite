class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.integer :visibility, null: false, default: 0  # 0=private, 1=public
      t.timestamps
    end
  end
end
