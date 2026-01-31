# frozen_string_literal: true

module Spree
  class MfaBackupCodesJob < ApplicationJob
    queue_as :default

    def perform(user_id, admin_id)
      user = Spree::User.find(user_id)
      admin = Spree::User.find_by(id: admin_id)

      original_cost = ::BCrypt::Engine.cost
      ::BCrypt::Engine.cost = ::BCrypt::Engine::MIN_COST
      codes = user.generate_otp_backup_codes!
      user.save!
    ensure
      ::BCrypt::Engine.cost = original_cost

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
