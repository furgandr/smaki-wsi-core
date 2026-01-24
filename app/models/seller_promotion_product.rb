# frozen_string_literal: true

class SellerPromotionProduct < ApplicationRecord
  belongs_to :seller_promotion
  belongs_to :product, class_name: "Spree::Product"

  validates :product_id, uniqueness: { scope: :seller_promotion_id }
end
