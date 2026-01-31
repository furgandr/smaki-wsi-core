# frozen_string_literal: true

class CreateMfaEmailCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :mfa_email_codes do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :sent_at, null: false
      t.datetime :consumed_at
      t.integer :attempts, null: false, default: 0

      t.timestamps
    end

    add_index :mfa_email_codes, [:user_id, :consumed_at]
  end
end
