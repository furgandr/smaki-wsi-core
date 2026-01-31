# frozen_string_literal: true

class MfaEmailCode < ApplicationRecord
  CODE_TTL = 5.minutes
  RESEND_WINDOW = 1.minute
  MAX_ATTEMPTS = 5

  belongs_to :user, class_name: "Spree::User"

  validates :code_digest, :expires_at, :sent_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.zone.now) }

  def self.issue_for(user)
    last = where(user:).order(sent_at: :desc).first
    if last&.sent_at && last.sent_at > RESEND_WINDOW.ago
      return [:rate_limited, last]
    end

    code = format("%06d", SecureRandom.random_number(1_000_000))
    digest = Digest::SHA256.hexdigest(code)

    record = create!(
      user:,
      code_digest: digest,
      sent_at: Time.zone.now,
      expires_at: CODE_TTL.from_now
    )

    [:ok, record, code]
  end

  def valid_code?(code)
    return false if consumed_at.present? || expires_at.past? || attempts >= MAX_ATTEMPTS

    digest = Digest::SHA256.hexdigest(code.to_s)
    ActiveSupport::SecurityUtils.secure_compare(code_digest, digest)
  end

  def consume!
    update!(consumed_at: Time.zone.now)
  end

  def bump_attempts!
    increment!(:attempts)
  end
end
