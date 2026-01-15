# frozen_string_literal: true

namespace :ofn do
  namespace :payment_methods do
    desc "Configure Przelewy24 payment methods from ENV"
    task przelewy24: :environment do
      required = %w[P24_MERCHANT_ID P24_API_KEY P24_CRC_KEY]
      missing = required.select { |key| ENV[key].to_s.strip.empty? }
      placeholder = required.select { |key| ENV[key].to_s.strip == "CHANGE_ME" }

      if missing.any? || placeholder.any?
        puts "P24 setup skipped: missing or placeholder credentials."
        puts "Set #{(missing + placeholder).uniq.join(', ')} to run setup."
        next
      end

      env = Rails.env
      merchant_id = ENV["P24_MERCHANT_ID"].to_i
      pos_id = ENV["P24_POS_ID"].presence&.to_i || merchant_id
      api_key = ENV["P24_API_KEY"].to_s
      crc_key = ENV["P24_CRC_KEY"].to_s
      language = ENV.fetch("P24_LANGUAGE", "pl")
      test_mode = ENV.fetch("P24_TEST_MODE", "true").casecmp("true").zero?
      wait_for_result = ENV.fetch("P24_WAIT_FOR_RESULT", "true").casecmp("true").zero?
      time_limit = ENV["P24_TIME_LIMIT"].presence&.to_i
      channel = ENV["P24_CHANNEL"].presence&.to_i
      method_id = ENV["P24_METHOD_ID"].presence&.to_i

      assign_all = ENV.fetch("P24_ASSIGN_ALL_DISTRIBUTORS", "false").casecmp("true").zero?
      distributors = assign_all ? Enterprise.is_distributor.to_a : []

      standard = Spree::Gateway::Przelewy24.find_or_initialize_by(
        name: "Przelewy24",
        environment: env
      )
      standard.active = true
      standard.display_on = "both"
      standard.preferred_merchant_id = merchant_id
      standard.preferred_pos_id = pos_id
      standard.preferred_api_key = api_key
      standard.preferred_crc_key = crc_key
      standard.preferred_language = language
      standard.preferred_test_mode = test_mode
      standard.preferred_wait_for_result = wait_for_result
      standard.preferred_time_limit = time_limit if time_limit
      standard.preferred_channel = channel if channel
      standard.preferred_method_id = method_id if method_id
      standard.save!
      standard.distributors = distributors if assign_all

      blik = Spree::Gateway::Przelewy24Blik.find_or_initialize_by(
        name: "Przelewy24 BLIK",
        environment: env
      )
      blik.active = true
      blik.display_on = "both"
      blik.preferred_merchant_id = merchant_id
      blik.preferred_pos_id = pos_id
      blik.preferred_api_key = api_key
      blik.preferred_crc_key = crc_key
      blik.preferred_language = language
      blik.preferred_test_mode = test_mode
      blik.preferred_wait_for_result = wait_for_result
      blik.preferred_time_limit = time_limit if time_limit
      blik.preferred_channel = ENV["P24_BLIK_CHANNEL"].presence&.to_i || 8192
      blik.preferred_method_id = ENV["P24_BLIK_METHOD_ID"].presence&.to_i if ENV["P24_BLIK_METHOD_ID"].present?
      blik.save!
      blik.distributors = distributors if assign_all

      puts "P24 payment methods configured."
    end
  end
end
