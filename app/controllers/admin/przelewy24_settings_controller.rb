# frozen_string_literal: true

module Admin
  class Przelewy24SettingsController < Spree::Admin::BaseController
    Przelewy24Settings = Struct.new(:przelewy24_enabled)

    before_action :load_settings, only: [:edit]

    def edit
      @credentials = credentials_status
    end

    def update
      Spree::Config.set(settings_params.to_h)
      resource = t("admin.controllers.przelewy24_settings.resource")
      flash[:success] = t(:successfully_updated, resource:)
      redirect_to main_app.edit_admin_przelewy24_settings_path
    end

    private

    def load_settings
      @settings = Przelewy24Settings.new(Spree::Config[:przelewy24_enabled])
    end

    def settings_params
      params.require(:settings).permit(:przelewy24_enabled)
    end

    def credentials_status
      required = %w[P24_MERCHANT_ID P24_API_KEY P24_CRC_KEY]
      missing = required.select { |key| ENV[key].to_s.strip.empty? }

      return { status: :missing } if missing.any?

      {
        status: :ok,
        merchant_id: ENV["P24_MERCHANT_ID"],
        pos_id: ENV["P24_POS_ID"],
        api_key: obfuscate(ENV["P24_API_KEY"]),
        crc_key: obfuscate(ENV["P24_CRC_KEY"])
      }
    end

    def obfuscate(value)
      return "" if value.to_s.empty?

      value = value.to_s
      "#{value.first(4)}****#{value.last(4)}"
    end
  end
end
