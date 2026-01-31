# frozen_string_literal: true

class CreateMfaAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :mfa_audit_logs do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.references :admin, null: false, foreign_key: { to_table: :spree_users }
      t.string :action, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :mfa_audit_logs, :action
  end
end
