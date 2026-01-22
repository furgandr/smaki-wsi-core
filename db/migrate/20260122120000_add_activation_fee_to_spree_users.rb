# frozen_string_literal: true

class AddActivationFeeToSpreeUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_users, :activation_fee_paid_at, :datetime
    add_column :spree_users, :activation_fee_exempt, :boolean, default: false, null: false
  end
end
