# frozen_string_literal: true

class EnterpriseRating < ApplicationRecord
  DUPLICATE_GAP = 3.days
  belongs_to :enterprise
  belongs_to :order, class_name: "Spree::Order"
  belongs_to :user, class_name: "Spree::User"

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :order_id, uniqueness: {
    scope: [:enterprise_id, :user_id],
    conditions: -> { where(removed_at: nil) }
  }

  validate :order_is_shipped
  validate :order_not_canceled
  validate :enterprise_in_order
  validate :user_matches_order
  validate :within_review_window
  before_validation :apply_duplicate_exclusion

  def recommend?
    rating.to_i >= 4
  end

  def stats_timestamp
    updated_at || created_at
  end

  def removal_requestable?(requester)
    return false if requester.nil? || removal_requested_at.present?
    return false if recommend?
    return false unless order&.review_request_window_open?
    return false unless enterprise&.users&.include?(requester)

    true
  end

  def request_removal!(requester)
    return false unless removal_requestable?(requester)

    update(removal_requested_at: Time.zone.now, removal_requested_by: requester)
  end

  private

  def order_is_shipped
    return if order&.shipped?

    errors.add(:order, I18n.t("ratings.errors.order_not_shipped"))
  end

  def order_not_canceled
    return unless order&.canceled?

    errors.add(:order, I18n.t("ratings.errors.order_canceled"))
  end

  def enterprise_in_order
    return if order.nil? || enterprise.nil?
    return if enterprise_is_supplier_in_order?
    return if order.distributor_id == enterprise.id

    errors.add(:enterprise, I18n.t("ratings.errors.enterprise_not_in_order"))
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

  def enterprise_is_supplier_in_order?
    order.line_items.joins(variant: :supplier)
      .where(spree_variants: { supplier_id: enterprise.id }).exists?
  end

  def apply_duplicate_exclusion
    return if excluded_from_stats? && excluded_reason.present?
    return if enterprise_id.nil? || user_id.nil?

    recent = EnterpriseRating
      .where(enterprise_id:, user_id:)
      .where.not(id: id)
      .where("updated_at >= ?", DUPLICATE_GAP.ago)
      .order(updated_at: :desc)
      .first

    if recent.present?
      self.excluded_from_stats = true
      self.excluded_reason = "duplicate_recent"
    end
  end
end
