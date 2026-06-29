class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :board, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :activities, [:board_id, :created_at]
    add_index :activities, [:subject_type, :subject_id]
  end
end
