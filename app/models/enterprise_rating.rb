# frozen_string_literal: true

class EnterpriseRating < ApplicationRecord
  belongs_to :enterprise
  belongs_to :order, class_name: "Spree::Order"
  belongs_to :user, class_name: "Spree::User"

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :order_id, uniqueness: { scope: [:enterprise_id, :user_id] }

  validate :order_is_complete
  validate :enterprise_in_order
  validate :user_matches_order

  private

  def order_is_complete
    return if order&.complete?

    errors.add(:order, I18n.t("ratings.errors.order_not_complete"))
  end

  def enterprise_in_order
    return if order.nil? || enterprise.nil?
    return if order.line_items.joins(variant: :supplier)
      .where(spree_variants: { supplier_id: enterprise.id }).exists?

    errors.add(:enterprise, I18n.t("ratings.errors.enterprise_not_in_order"))
  end

  def user_matches_order
    return if order.nil? || user.nil?
    return if order.user_id == user.id

    errors.add(:user, I18n.t("ratings.errors.user_not_order_owner"))
  end
end
