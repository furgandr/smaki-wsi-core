# frozen_string_literal: true

class MfaLoginToken < ApplicationRecord
  TTL = 10.minutes

  belongs_to :user, class_name: "Spree::User"

  validates :token_digest, :mfa_method, :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.zone.now) }

  def self.issue_for(user, mfa_method)
    raw = SecureRandom.hex(32)
    digest = Digest::SHA256.hexdigest(raw)
    create!(
      user:,
      mfa_method:,
      token_digest: digest,
      expires_at: TTL.from_now
    )
    raw
  end

  def valid_token?(token)
    return false if consumed_at.present? || expires_at.past?

    digest = Digest::SHA256.hexdigest(token.to_s)
    ActiveSupport::SecurityUtils.secure_compare(token_digest, digest)
  end

  def consume!
    update!(consumed_at: Time.zone.now)
  end
end
