# frozen_string_literal: true

class AddSellerResponseToProductReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :product_reviews, :seller_response, :text
    add_column :product_reviews, :seller_response_updated_at, :datetime
    add_column :product_reviews, :seller_responder_id, :integer
  end
end
