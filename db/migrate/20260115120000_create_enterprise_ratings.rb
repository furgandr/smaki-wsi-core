# frozen_string_literal: true

class CreateEnterpriseRatings < ActiveRecord::Migration[7.0]
  def change
    create_table :enterprise_ratings do |t|
      t.references :enterprise, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: { to_table: :spree_orders }
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_index :enterprise_ratings, [:order_id, :enterprise_id, :user_id],
              unique: true,
              name: "index_enterprise_ratings_on_order_enterprise_user"
  end
end
