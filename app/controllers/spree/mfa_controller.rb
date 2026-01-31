# frozen_string_literal: true

module Spree
  class MfaController < ::BaseController
    include MfaHelpers

    layout "spree/layouts/bare_admin"

    before_action :authenticate_spree_user!

    def choice
      return redirect_to otp_setup_path if spree_current_user.admin?

      case spree_current_user.mfa_method
      when "totp"
        redirect_to otp_setup_path
      when "email"
        redirect_to mfa_email_path
      else
        render :choice
      end
    end

    def set_method
      method = params[:mfa_method].to_s
      if method == "totp"
        spree_current_user.update!(mfa_method: "totp")
        redirect_to otp_setup_path
      elsif method == "email"
        spree_current_user.update!(mfa_method: "email")
        redirect_to mfa_email_path
      else
        redirect_to mfa_choice_path
      end
    end

    def otp_setup
      spree_current_user.ensure_totp_secret!
      issuer = Spree::Config[:site_name].presence || "Smaki Wsi"
      @qr = RQRCode::QRCode.new(
        spree_current_user.otp_provisioning_uri(spree_current_user.email, issuer:)
      )
    end

    def otp_verify
      code = params[:otp_code].to_s

      if spree_current_user.validate_and_consume_otp!(code)
        spree_current_user.update!(otp_required_for_login: true, mfa_method: "totp")
        mark_mfa_verified!(spree_current_user, method: "totp", trust_device: trust_device?)
        redirect_to after_mfa_redirect
      else
        flash.now[:error] = I18n.t("mfa.invalid_code")
        issuer = Spree::Config[:site_name].presence || "Smaki Wsi"
        @qr = RQRCode::QRCode.new(
          spree_current_user.otp_provisioning_uri(spree_current_user.email, issuer:)
        )
        render :otp_setup, status: :unprocessable_entity
      end
    end

    def email_challenge
      status, record, code = MfaEmailCode.issue_for(spree_current_user)
      if status == :rate_limited
        flash.now[:error] = I18n.t("mfa.too_many_requests")
      else
        Spree::UserMailer.mfa_code(spree_current_user, code).deliver_later
      end

      @email_code = record
    end

    def email_verify
      code = params[:email_code].to_s
      record = spree_current_user.mfa_email_codes.active.order(sent_at: :desc).first

      if record&.valid_code?(code)
        record.consume!
        spree_current_user.update!(mfa_method: "email") unless spree_current_user.admin?
        mark_mfa_verified!(spree_current_user, method: "email", trust_device: trust_device?)
        redirect_to after_mfa_redirect
      else
        record&.bump_attempts!
        flash.now[:error] = I18n.t("mfa.invalid_code")
        render :email_challenge, status: :unprocessable_entity
      end
    end

    def skip
      return redirect_to mfa_choice_path if spree_current_user.admin?

      spree_current_user.update!(mfa_method: "none")
      clear_mfa_session!
      redirect_to after_mfa_redirect
    end

    private

    def trust_device?
      params[:trust_device].to_s == "1"
    end

    def after_mfa_redirect
      session.delete(:mfa_return_to) || spree.admin_dashboard_path
    end
  end
end
