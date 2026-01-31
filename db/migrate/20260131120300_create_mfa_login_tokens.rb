# frozen_string_literal: true

class CreateMfaLoginTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :mfa_login_tokens do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.string :token_digest, null: false
      t.string :mfa_method, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at

      t.timestamps
    end

    add_index :mfa_login_tokens, [:user_id, :consumed_at]
    add_index :mfa_login_tokens, :token_digest, unique: true
  end
end
