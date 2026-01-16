# frozen_string_literal: true

class AdjustUniqueIndexOnEnterpriseRatings < ActiveRecord::Migration[7.0]
  def change
    remove_index :enterprise_ratings, name: "index_enterprise_ratings_on_order_enterprise_user"
    add_index :enterprise_ratings, [:order_id, :enterprise_id, :user_id],
              unique: true,
              where: "removed_at IS NULL",
              name: "index_enterprise_ratings_on_order_enterprise_user_active"
  end
end
