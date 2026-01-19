# frozen_string_literal: true

class CreateProductReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: { to_table: :spree_products }
      t.references :order, null: false, foreign_key: { to_table: :spree_orders }
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_index :product_reviews, [:product_id, :user_id],
              unique: true,
              name: "index_product_reviews_on_product_and_user"
  end
end
