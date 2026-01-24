# frozen_string_literal: true

class AddActivationFeeUserIdToSpreeOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_orders, :activation_fee_user_id, :integer
    add_index :spree_orders, :activation_fee_user_id
  end
end
