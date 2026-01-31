# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Activation fee enforcement (web)", type: :request do
  # NOTE: These specs cover existing enterprises. New enterprise creation remains
  # gated by activation fee via model validation (sells: unspecified -> own/any).
  let(:owner) { create(:user) }
  let(:enterprise) do
    create(:enterprise, owner:, sells: "unspecified", visible: "only_through_links")
  end

  around do |example|
    original_enabled = Spree::Config[:activation_fee_enabled]
    original_free_limit = Spree::Config[:activation_fee_free_limit]
    Spree::Config[:activation_fee_enabled] = true
    Spree::Config[:activation_fee_free_limit] = 0
    example.run
  ensure
    Spree::Config[:activation_fee_enabled] = original_enabled
    Spree::Config[:activation_fee_free_limit] = original_free_limit
  end

  before do
    sign_in owner
  end

  it "does not block sells change for existing enterprises even when activation fee is required" do
    patch admin_enterprise_path(enterprise), params: { enterprise: { sells: "own" } }
    expect(enterprise.reload.sells).to eq("own")
  end

  it "allows activation when fee is paid" do
    owner.update!(activation_fee_paid_at: Time.zone.now)
    patch admin_enterprise_path(enterprise), params: { enterprise: { sells: "own" } }
    expect(enterprise.reload.sells).to eq("own")
  end

  it "allows activation when activation fee is disabled" do
    Spree::Config[:activation_fee_enabled] = false
    patch admin_enterprise_path(enterprise), params: { enterprise: { sells: "own" } }
    expect(enterprise.reload.sells).to eq("own")
  end
end
