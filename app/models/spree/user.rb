# frozen_string_literal: true

require "digest"
require "bcrypt"

module Spree
  class User < ApplicationRecord
    include SetUnusedAddressFields

    self.belongs_to_required_by_default = false

    searchable_attributes :email

    devise :database_authenticatable, :token_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :omniauthable,
           :encryptable, :confirmable, :two_factor_authenticatable, :two_factor_backupable,
           encryptor: 'authlogic_sha512', reconfirmable: true,
           omniauth_providers: [:openid_connect]

    has_many :orders, dependent: nil
    belongs_to :ship_address, class_name: 'Spree::Address'
    belongs_to :bill_address, class_name: 'Spree::Address'

    before_validation :set_login
    after_create :associate_customers, :associate_orders
    before_destroy :check_completed_orders

    scope :admin, -> { where(admin: true) }

    has_many :enterprise_roles, dependent: :destroy
    has_many :enterprises, through: :enterprise_roles
    has_many :owned_enterprises, class_name: 'Enterprise',
                                 foreign_key: :owner_id, inverse_of: :owner,
                                 dependent: :restrict_with_exception
    has_many :owned_groups, class_name: 'EnterpriseGroup',
                            foreign_key: :owner_id, inverse_of: :owner,
                            dependent: :restrict_with_exception
    has_many :customers, dependent: :destroy
    has_many :credit_cards, dependent: :destroy
    has_many :report_rendering_options, class_name: "::ReportRenderingOptions", dependent: :destroy
    has_many :product_reviews, class_name: "::ProductReview", dependent: :destroy
    has_many :enterprise_ratings, class_name: "::EnterpriseRating", dependent: :destroy
    has_many :webhook_endpoints, dependent: :destroy
    has_many :column_preferences, dependent: :destroy
    has_many :trusted_devices, class_name: "::TrustedDevice", dependent: :destroy
    has_many :mfa_email_codes, class_name: "::MfaEmailCode", dependent: :destroy
    has_many :mfa_login_tokens, class_name: "::MfaLoginToken", dependent: :destroy
    has_one :oidc_account, dependent: :destroy

    accepts_nested_attributes_for :enterprise_roles, allow_destroy: true
    accepts_nested_attributes_for :webhook_endpoints

    accepts_nested_attributes_for :bill_address,
                                  reject_if: ->(attrs) { Spree::Address.new(attrs).empty? }
    accepts_nested_attributes_for :ship_address,
                                  reject_if: ->(attrs) { Spree::Address.new(attrs).empty? }

    validates :email, 'valid_email_2/email': { mx: true }, if: :email_changed?
    validate :limit_owned_enterprises

    MFA_METHODS = %w[none totp email].freeze

    alias_attribute :otp_secret_key, :otp_secret

    validates :mfa_method, inclusion: { in: MFA_METHODS }

    class DestroyWithOrdersError < StandardError; end

    def self.admin_created?
      User.admin.count > 0
    end

    def mfa_required?
      return true if admin?

      mfa_method.present? && mfa_method != "none"
    end

    def mfa_totp_only?
      admin? || mfa_method == "totp"
    end

    def mfa_email?
      mfa_method == "email"
    end

    def ensure_totp_secret!
      return if otp_secret.present?

      self.otp_secret = ROTP::Base32.random
      save!(validate: false)
    end

    def generate_fast_otp_backup_codes!
      count = if Devise.respond_to?(:otp_backup_codes_count)
                Devise.otp_backup_codes_count
              else
                10
              end
      length = if Devise.respond_to?(:otp_backup_code_length)
                 Devise.otp_backup_code_length
               else
                 10
               end

      codes = Array.new(count) { SecureRandom.hex((length / 2.0).ceil)[0, length] }
      self.otp_backup_codes = codes.map { |code| Digest::SHA256.hexdigest(code) }
      save!(validate: false)
      codes
    end

    def consume_backup_code!(code)
      return false if code.blank? || otp_backup_codes.blank?

      hashed = Digest::SHA256.hexdigest(code)
      if otp_backup_codes.delete(hashed)
        update!(otp_backup_codes: otp_backup_codes)
        return true
      end

      otp_backup_codes.each do |stored|
        next unless stored.start_with?("$2")

        if ::BCrypt::Password.new(stored).is_password?(code)
          otp_backup_codes.delete(stored)
          update!(otp_backup_codes: otp_backup_codes)
          return true
        end
      end

      false
    end

    # Send devise-based user emails asyncronously via ActiveJob
    # See: https://github.com/heartcombo/devise/tree/v3.5.10#activejob-integration
    def send_devise_notification(notification, *)
      devise_mailer.public_send(notification, self, *).deliver_later
    end

    def regenerate_reset_password_token
      set_reset_password_token
    end

    def generate_api_key
      self.spree_api_key = SecureRandom.hex(24)
    end

    def known_users
      if admin?
        Spree::User.where(nil)
      else
        Spree::User
          .includes(:enterprises)
          .references(:enterprises)
          .where("enterprises.id IN (SELECT enterprise_id FROM enterprise_roles WHERE user_id = ?)",
                 id)
      end
    end

    def build_enterprise_roles
      Enterprise.find_each do |enterprise|
        unless enterprise_roles.find_by enterprise_id: enterprise.id
          enterprise_roles.build(enterprise:)
        end
      end
    end

    def customer_of(enterprise)
      return nil unless enterprise

      customers.find_by(enterprise_id: enterprise)
    end

    # This is a Devise Confirmable callback that runs on email confirmation
    # It sends a welcome email after the user email is confirmed
    def after_confirmation
      return unless confirmed? && unconfirmed_email.nil? && !unconfirmed_email_changed?

      send_signup_confirmation
    end

    def send_signup_confirmation
      Spree::UserMailer.signup_confirmation(self).deliver_later
    end

    def associate_customers
      self.customers = Customer.where(email:)
    end

    def associate_orders
      Spree::Order.where(customer: customers).find_each do |order|
        order.associate_user!(self)
      end
    end

    def can_own_more_enterprises?
      owned_enterprises.reload.size < enterprise_limit
    end

    def activation_fee_paid?
      activation_fee_paid_at.present?
    end

    def activation_fee_exempt?
      activation_fee_exempt
    end

    def activation_fee_free?
      free_limit = Spree::Config[:activation_fee_free_limit].to_i
      return false if free_limit <= 0 || id.nil?

      self.class.order(:created_at, :id).limit(free_limit).where(id: id).exists?
    end

    def activation_fee_required?
      return false unless Spree::Config[:activation_fee_enabled]
      return false if admin?
      return false if activation_fee_paid? || activation_fee_exempt? || activation_fee_free?

      true
    end

    def default_card
      # Don't re-fetch associated cards from the DB if they're already eager-loaded
      if credit_cards.loaded?
        credit_cards.to_a.find(&:is_default)
      else
        credit_cards.where(is_default: true).first
      end
    end

    def last_incomplete_spree_order
      orders.incomplete.where(created_by_id: id).order('created_at DESC').first
    end

    def disabled
      disabled_at.present?
    end

    def disabled=(value)
      self.disabled_at = value == '1' ? Time.zone.now : nil
    end

    def affiliate_enterprises
      return [] unless Flipper.enabled?(:affiliate_sales_data, self)

      Enterprise.joins(:connected_apps).merge(ConnectedApps::AffiliateSalesData.ready)
    end

    # Users can manage orders if they have a sells own/any enterprise. or is admin
    def can_manage_orders?
      @can_manage_orders ||= (enterprises.pluck(:sells).intersect?(%w(own any)) or admin?)
    end

    # Users can manage line items in orders if they have producer enterprise and
    # any of order distributors allow them to edit their orders.
    def can_manage_line_items_in_orders?
      return @can_manage_line_items_in_orders if defined? @can_manage_line_items_in_orders

      @can_manage_line_items_in_orders =
        enterprises.any?(&:is_producer_only) &&
        Spree::Order.editable_by_producers(enterprises).exists?
    end

    def can_manage_line_items_in_orders_only?
      !can_manage_orders? && can_manage_line_items_in_orders?
    end

    protected

    def password_required?
      !persisted? || password.present? || password_confirmation.present?
    end

    private

    def check_completed_orders
      raise DestroyWithOrdersError if orders.complete.present?
    end

    def set_login
      # for now force login to be same as email, eventually we will make this configurable, etc.
      self.login ||= email if email
    end

    def limit_owned_enterprises
      return unless owned_enterprises.size > enterprise_limit

      errors.add(:owned_enterprises, I18n.t(:spree_user_enterprise_limit_error,
                                            email:,
                                            enterprise_limit:))
    end

    def remove_payments_in_checkout(enterprises)
      enterprises.each do |enterprise|
        enterprise.distributed_orders.each do |order|
          order.payments.keep_if { |payment| payment.state != "checkout" }
        end
      end
    end
  end
end
