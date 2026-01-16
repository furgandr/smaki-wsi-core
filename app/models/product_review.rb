# frozen_string_literal: true

class ProductReview < ApplicationRecord
  belongs_to :product, class_name: "Spree::Product"
  belongs_to :order, class_name: "Spree::Order"
  belongs_to :user, class_name: "Spree::User"

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :product_id, uniqueness: { scope: :user_id }

  validate :order_is_shipped
  validate :order_not_canceled
  validate :product_in_order
  validate :user_matches_order
  validate :within_review_window

  private

  def order_is_shipped
    return if order&.shipped?

    errors.add(:order, I18n.t("ratings.errors.order_not_shipped"))
  end

  def order_not_canceled
    return unless order&.canceled?

    errors.add(:order, I18n.t("ratings.errors.order_canceled"))
  end

  def product_in_order
    return if order.nil? || product.nil?
    return if order.line_items.joins(:product).where(spree_products: { id: product.id }).exists?

    errors.add(:product, I18n.t("product_reviews.errors.product_not_in_order"))
  end

  def user_matches_order
    return if order.nil? || user.nil?
    return if order.user_id == user.id

    errors.add(:user, I18n.t("ratings.errors.user_not_order_owner"))
  end

  def within_review_window
    return if order.nil?
    return if order.review_window_open?

    errors.add(:order, I18n.t("ratings.errors.review_window_closed"))
  end
end
