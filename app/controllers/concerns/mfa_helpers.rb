# frozen_string_literal: true

module MfaHelpers
  TRUST_DAYS = 30

  def mfa_required_for_user?(user)
    return false if user.blank?
    return true if user.admin?

    user.mfa_method.present? && user.mfa_method != "none"
  end

  def mfa_verified_for_user?(user)
    return false if user.blank?
    return true if trusted_device_for_user?(user)

    session[:mfa_verified_user_id].to_i == user.id
  end

  def mark_mfa_verified!(user, method:, trust_device: false)
    session[:mfa_verified_user_id] = user.id
    session[:mfa_verified_method] = method

    return unless trust_device

    fingerprint = mfa_fingerprint
    return if fingerprint.blank?

    device = TrustedDevice.find_or_initialize_by(user:, fingerprint:)
    device.mfa_method = method
    device.expires_at = TRUST_DAYS.days.from_now
    device.last_used_at = Time.zone.now
    device.save!
  end

  def clear_mfa_session!
    session.delete(:mfa_verified_user_id)
    session.delete(:mfa_verified_method)
    session.delete(:mfa_return_to)
  end

  def trusted_device_for_user?(user)
    return false if user.blank?

    fingerprint = mfa_fingerprint
    return false if fingerprint.blank?

    device = TrustedDevice.active.find_by(user:, fingerprint:)
    return false if device.blank?

    device.touch_last_used!
    true
  end

  def mfa_fingerprint
    raw = "#{request.user_agent}|#{request.remote_ip}"
    return nil if raw.blank?

    Digest::SHA256.hexdigest(raw)
  end
end
