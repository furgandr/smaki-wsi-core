# frozen_string_literal: true

class AddReviewRequestTrackingToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_orders, :review_request_sent_at, :datetime
    add_column :spree_orders, :review_reminder_sent_at, :datetime
  end
end
