# frozen_string_literal: true

module Reviews
  class OrderReviewRequestService
    def initialize(order)
      @order = order
    end

    def schedule
      return unless eligible_for_request?

      Spree::OrderMailer.review_request_email(@order).deliver_later
      @order.update_column(:review_request_sent_at, Time.zone.now)

      Reviews::ReviewReminderJob.set(wait: 7.days).perform_later(@order.id)
    end

    private

    def eligible_for_request?
      @order.user.present? &&
        @order.shipped? &&
        @order.review_window_open? &&
        @order.review_request_sent_at.nil?
    end
  end
end
