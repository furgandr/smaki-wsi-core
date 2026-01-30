# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin enterprises locale", type: :request do
  let(:admin) { create(:admin_user) }
  let!(:enterprise) { create(:enterprise) }

  around do |example|
    original_default_locale = I18n.default_locale
    original_available_locales = Rails.application.config.i18n.available_locales

    I18n.default_locale = :pl
    Rails.application.config.i18n.available_locales = [:pl, :en]

    example.run
  ensure
    I18n.default_locale = original_default_locale
    Rails.application.config.i18n.available_locales = original_available_locales
  end

  before do
    sign_in admin
  end

  it "renders Polish labels on the enterprises index" do
    get admin_enterprises_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Podmioty")
  end

  it "renders Polish labels on the enterprise edit page" do
    get edit_admin_enterprise_path(enterprise)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Ustawienia:")
  end
end
