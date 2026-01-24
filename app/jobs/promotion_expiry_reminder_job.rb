# frozen_string_literal: true

class PromotionExpiryReminderJob < ApplicationJob
  queue_as :mailers

  def perform
    expire_promotions
    send_reminders
  end

  private

  def expire_promotions
    now = Time.current
    SellerPromotion.where(status: ["active", "scheduled"]).where("ends_at <= ?", now)
      .update_all(status: "expired", updated_at: now)
  end

  def send_reminders
    now = Time.current
    window_start = (now + 3.days).beginning_of_day
    window_end = (now + 3.days).end_of_day

    SellerPromotion.active.where(reminder_sent_at: nil, ends_at: window_start..window_end)
      .find_each do |promotion|
        PromotionMailer.expiring_soon(promotion).deliver_later
        promotion.update_column(:reminder_sent_at, now)
      end
  end
end
