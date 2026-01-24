# frozen_string_literal: true

class PromotionPlan < ApplicationRecord
  has_many :seller_promotions, dependent: :restrict_with_exception

  validates :name, :sku, :duration_days, :price_cents, :currency, presence: true
  validates :duration_days, numericality: { greater_than: 0, only_integer: true }
  validates :price_cents, numericality: { greater_than: 0, only_integer: true }
  validates :sku, uniqueness: true

  scope :active, -> { where(active: true) }

  def price
    Spree::Money.new(price_cents / 100.0, currency:)
  end
end
