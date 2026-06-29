class CreateWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :webhooks do |t|
      t.references :board, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false
      t.jsonb :event_types, null: false, default: []
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
