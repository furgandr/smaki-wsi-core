# frozen_string_literal: true

class TrustedDevice < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"

  validates :fingerprint, :mfa_method, :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.zone.now) }

  def touch_last_used!
    update_column(:last_used_at, Time.zone.now)
  end
end
