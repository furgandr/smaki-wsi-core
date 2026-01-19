# frozen_string_literal: true

module Reviews
  class ReviewReminderJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = Spree::Order.find_by(id: order_id)
      return if order.nil?
      return if order.review_reminder_sent_at.present?
      return unless order.review_window_open?
      return unless order.reviews_pending_for_user?(order.user)

      Spree::OrderMailer.review_reminder_email(order).deliver_later
      order.update_column(:review_reminder_sent_at, Time.zone.now)
    end
  end
end
