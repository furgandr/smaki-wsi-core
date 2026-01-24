# frozen_string_literal: true

class CreateSellerPromotionProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :seller_promotion_products do |t|
      t.references :seller_promotion, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: { to_table: :spree_products }

      t.timestamps
    end

    add_index :seller_promotion_products, [:seller_promotion_id, :product_id], unique: true,
      name: "index_seller_promotion_products_on_promotion_and_product"
  end
end
