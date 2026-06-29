class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event, null: false
      t.jsonb :payload, null: false, default: {}
      t.integer :status, null: false, default: 0  # 0=pending,1=delivered,2=failed
      t.integer :response_code
      t.text :response_body
      t.integer :attempts, null: false, default: 0
      t.datetime :delivered_at
      t.timestamps
    end
  end
end
