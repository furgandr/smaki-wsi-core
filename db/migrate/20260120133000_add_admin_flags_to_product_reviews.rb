# frozen_string_literal: true

class AddAdminFlagsToProductReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :product_reviews, :removed_at, :datetime
    add_column :product_reviews, :removal_reason, :string
    add_column :product_reviews, :excluded_from_stats, :boolean, default: false, null: false
    add_column :product_reviews, :excluded_reason, :string
  end
end
