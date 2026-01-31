# frozen_string_literal: true

class AddMfaFieldsToSpreeUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :otp_secret, :string
    add_column :spree_users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :spree_users, :otp_backup_codes, :text
    add_column :spree_users, :mfa_method, :string, default: "none", null: false

    add_index :spree_users, :mfa_method
  end
end
