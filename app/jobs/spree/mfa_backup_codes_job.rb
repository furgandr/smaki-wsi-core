# frozen_string_literal: true

module Spree
  class MfaBackupCodesJob < ApplicationJob
    queue_as :default

    def perform(user_id, admin_id)
      user = Spree::User.find(user_id)
      admin = Spree::User.find_by(id: admin_id)

      codes = user.generate_fast_otp_backup_codes!
    ensure

      Rails.cache.write(cache_key(user_id), codes, expires_in: 10.minutes)

      MfaAuditLog.create!(
        user: user,
        admin: admin,
        action: MfaAuditLog::ACTION_RESET,
        metadata: { source: "admin/users#generate_mfa_backup_codes" }
      )
    end

    private

    def cache_key(user_id)
      "mfa_backup_codes:#{user_id}"
    end
  end
end
