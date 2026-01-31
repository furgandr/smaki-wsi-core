# frozen_string_literal: true

module Api
  module V1
    class AuthController < ActionController::API

      rescue_from ActiveRecord::RecordNotFound, with: :unauthorized

      def login
        user = Spree::User.find_by!(email: params[:email].to_s.downcase)

        unless user.valid_password?(params[:password].to_s)
          return render status: :unauthorized, json: { error: "invalid_credentials" }
        end

        if mfa_required_for_user?(user) && !trusted_device_for_user?(user)
          method = user.admin? ? "totp" : (user.mfa_method.presence || "email")
          token = MfaLoginToken.issue_for(user, method)

          if method == "email"
            status, _record, code = MfaEmailCode.issue_for(user)
            Spree::UserMailer.mfa_code(user, code).deliver_later if status == :ok
          end

          return render json: { mfa_required: true, mfa_type: method, mfa_token: token }
        end

        render json: { mfa_required: false, token: JsonWebToken.encode({ user_id: user.id }) }
      end

      def verify_mfa
        token = params[:mfa_token].to_s
        code = params[:code].to_s
        login_token = MfaLoginToken.active.find_by(token_digest: Digest::SHA256.hexdigest(token))

        return render status: :unauthorized, json: { error: "invalid_mfa_token" } if login_token.blank?

        user = login_token.user
        method = login_token.mfa_method

        valid =
          if method == "totp"
            user.validate_and_consume_otp!(code)
          else
            record = user.mfa_email_codes.active.order(sent_at: :desc).first
            if record&.valid_code?(code)
              record.consume!
              true
            else
              record&.bump_attempts!
              false
            end
          end

        return render status: :unauthorized, json: { error: "invalid_code" } unless valid

        login_token.consume!
        trust_device_for_api!(user, method) if params[:trusted_device].to_s == "1"

        render json: { token: JsonWebToken.encode({ user_id: user.id }) }
      end

      def me_mfa
        user = authenticate_jwt!
        return unless user

        render json: {
          mfa_enabled: user.mfa_required?,
          mfa_method: user.admin? ? "totp" : user.mfa_method,
          trusted_devices: user.trusted_devices.active.map { |d|
            {
              id: d.id,
              mfa_method: d.mfa_method,
              expires_at: d.expires_at,
              last_used_at: d.last_used_at
            }
          }
        }
      end

      private

      def mfa_required_for_user?(user)
        return true if user.admin?

        user.mfa_method.present? && user.mfa_method != "none"
      end

      def trusted_device_for_user?(user)
        fingerprint = mfa_fingerprint
        return false if fingerprint.blank?

        device = TrustedDevice.active.find_by(user:, fingerprint:)
        return false if device.blank?

        device.touch_last_used!
        true
      end

      def trust_device_for_api!(user, method)
        fingerprint = mfa_fingerprint
        return if fingerprint.blank?

        device = TrustedDevice.find_or_initialize_by(user:, fingerprint:)
        device.mfa_method = method
        device.expires_at = MfaHelpers::TRUST_DAYS.days.from_now
        device.last_used_at = Time.zone.now
        device.save!
      end

      def mfa_fingerprint
        raw = "#{request.user_agent}|#{request.remote_ip}"
        return nil if raw.blank?

        Digest::SHA256.hexdigest(raw)
      end

      def authenticate_jwt!
        auth_header = request.headers["Authorization"].to_s
        token = auth_header.delete_prefix("Bearer ").strip
        return unauthorized if token.blank?

        payload = JsonWebToken.decode(token)
        Spree::User.find(payload["user_id"])
      rescue StandardError
        unauthorized
        nil
      end

      def unauthorized
        render status: :unauthorized, json: { error: "unauthorized" }
      end
    end
  end
end
