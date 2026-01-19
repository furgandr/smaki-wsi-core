# frozen_string_literal: true

class AddModerationToEnterpriseRatings < ActiveRecord::Migration[7.0]
  def change
    change_table :enterprise_ratings, bulk: true do |t|
      t.datetime :removed_at
      t.references :removed_by, foreign_key: { to_table: :spree_users }
      t.string :removal_reason
      t.boolean :excluded_from_stats, null: false, default: false
      t.string :excluded_reason
      t.datetime :removal_requested_at
      t.references :removal_requested_by, foreign_key: { to_table: :spree_users }
    end
  end
end
