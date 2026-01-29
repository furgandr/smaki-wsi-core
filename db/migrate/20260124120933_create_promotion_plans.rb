# frozen_string_literal: true

class CreatePromotionPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :promotion_plans do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.integer :duration_days, null: false
      t.integer :price_cents, null: false
      t.string :currency, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :promotion_plans, :sku, unique: true
  end
end
