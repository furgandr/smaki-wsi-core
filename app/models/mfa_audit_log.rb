# frozen_string_literal: true

class MfaAuditLog < ApplicationRecord
  ACTION_RESET = "reset".freeze

  belongs_to :user, class_name: "Spree::User"
  belongs_to :admin, class_name: "Spree::User"

  validates :action, presence: true
end
