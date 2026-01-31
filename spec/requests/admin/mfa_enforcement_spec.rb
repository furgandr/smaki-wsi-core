# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin MFA enforcement", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:enterprise_user) { create(:user, mfa_method: "email") }

  it "redirects superadmin to TOTP setup when missing OTP" do
    sign_in admin_user, scope: :spree_user

    get spree.admin_dashboard_path

    expect(response).to redirect_to(spree.otp_setup_path)
  end

  it "redirects enterprise user to configured MFA method" do
    sign_in enterprise_user, scope: :spree_user

    get spree.mfa_choice_path

    expect(response).to redirect_to(spree.mfa_email_path)
  end
end
