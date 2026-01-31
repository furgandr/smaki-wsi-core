# frozen_string_literal: true

require "spec_helper"

RSpec.describe "API MFA auth", type: :request do
  let(:user) { create(:user, mfa_method: "email") }

  it "returns mfa_required and then verifies email code" do
    post "/api/v1/auth/login", params: { email: user.email, password: "secret" }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload["mfa_required"]).to eq(true)
    expect(payload["mfa_type"]).to eq("email")

    code = "123456"
    MfaEmailCode.create!(
      user: user,
      code_digest: Digest::SHA256.hexdigest(code),
      sent_at: Time.zone.now,
      expires_at: 5.minutes.from_now
    )

    post "/api/v1/auth/verify_mfa", params: { mfa_token: payload["mfa_token"], code: code }
    expect(response).to have_http_status(:ok)
    verify_payload = JSON.parse(response.body)
    expect(verify_payload["token"]).to be_present
  end
end
