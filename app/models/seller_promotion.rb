# frozen_string_literal: true

class SellerPromotion < ApplicationRecord
  STATUSES = %w[pending scheduled active expired canceled].freeze
  MAX_PRODUCTS = 3

  belongs_to :supplier, class_name: "Enterprise"
  belongs_to :distributor, class_name: "Enterprise"
  belongs_to :promotion_plan
  belongs_to :order, class_name: "Spree::Order", optional: true

  has_many :seller_promotion_products, dependent: :destroy
  has_many :products, through: :seller_promotion_products, source: :product

  validates :status, inclusion: { in: STATUSES }
  validate :product_limit
  validate :product_presence
  validate :products_belong_to_supplier

  scope :active, -> { where(status: "active") }
  scope :pending, -> { where(status: "pending") }
  scope :scheduled, -> { where(status: "scheduled") }

  def active_on?(time)
    return false if starts_at.blank? || ends_at.blank?

    starts_at <= time && ends_at > time && status == "active"
  end

  private

  def product_limit
    return if product_ids.size <= MAX_PRODUCTS

    errors.add(:products, I18n.t("seller_promotions.errors.too_many_products", max: MAX_PRODUCTS))
  end

  def product_presence
    return if product_ids.any?

    errors.add(:products, I18n.t("seller_promotions.errors.missing_products"))
  end

  def products_belong_to_supplier
    return if products.empty? || supplier_id.blank?

    invalid_products = products.reject do |product|
      product.variants.first&.supplier_id == supplier_id
    end

    return if invalid_products.empty?

    errors.add(:products, I18n.t("seller_promotions.errors.invalid_supplier_products"))
  end
end
