# frozen_string_literal: true

class CreateTrustedDevices < ActiveRecord::Migration[7.0]
  def change
    create_table :trusted_devices do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.string :fingerprint, null: false
      t.string :mfa_method, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :trusted_devices, [:user_id, :fingerprint], unique: true
  end
end
