# frozen_string_literal: true

class CreateSellerPromotions < ActiveRecord::Migration[6.1]
  def change
    create_table :seller_promotions do |t|
      t.references :supplier, null: false, foreign_key: { to_table: :enterprises }
      t.references :distributor, null: false, foreign_key: { to_table: :enterprises }
      t.references :promotion_plan, null: false, foreign_key: true
      t.references :order, null: true, foreign_key: { to_table: :spree_orders }
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :status, null: false, default: "pending"
      t.datetime :reminder_sent_at

      t.timestamps
    end

    add_index :seller_promotions, :status
    add_index :seller_promotions, :ends_at
    add_index :seller_promotions, [:supplier_id, :distributor_id]
  end
end
