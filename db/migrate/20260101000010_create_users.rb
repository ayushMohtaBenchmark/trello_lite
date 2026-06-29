class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.citext :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0   # 0=member, 1=admin
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
