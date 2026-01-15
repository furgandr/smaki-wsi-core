# frozen_string_literal: true

require "securerandom"

module Checkout
  class Przelewy24Redirect
    include Rails.application.routes.url_helpers

    def initialize(payment_method, order)
      @payment_method = payment_method
      @order = order
    end

    def call
      payment = find_or_create_payment
      session_id = payment.identifier.presence || generate_session_id(payment)
      payment.update!(identifier: session_id)

      response = payment_method.client.register(register_payload(session_id))
      token = response.dig(:body, "data", "token")

      if response[:status] == 200 && response.dig(:body, "responseCode").to_i.zero? && token.present?
        "#{gateway_base_url}/trnRequest/#{token}"
      else
        order.errors.add(:base, I18n.t("payment_could_not_process"))
        nil
      end
    rescue StandardError
      order.errors.add(:base, I18n.t("payment_could_not_process"))
      nil
    end

    private

    attr_reader :payment_method, :order

    def gateway_base_url
      payment_method.preferred_test_mode ? "https://sandbox.przelewy24.pl" : "https://secure.przelewy24.pl"
    end

    def find_or_create_payment
      order.payments.where(payment_method_id: payment_method.id).order(:created_at).last ||
        order.payments.create!(amount: order.total, payment_method: payment_method)
    end

    def generate_session_id(payment)
      "ofn-#{order.number}-#{payment.id}-#{SecureRandom.hex(4)}"
    end

    def register_payload(session_id)
      amount = (order.total * 100).round
      currency = order.currency

      payload = {
        merchantId: payment_method.preferred_merchant_id,
        posId: payment_method.preferred_pos_id || payment_method.preferred_merchant_id,
        sessionId: session_id,
        amount: amount,
        currency: currency,
        description: "Order #{order.number}",
        email: order.email.to_s,
        country: country_code,
        language: payment_method.preferred_language,
        urlReturn: payment_gateways_przelewy24_return_url(order_number: order.number,
                                                          order_token: order.token),
        urlStatus: payment_gateways_przelewy24_status_url,
        waitForResult: payment_method.preferred_wait_for_result,
        sign: Przelewy24::Signature.register(
          session_id: session_id,
          merchant_id: payment_method.preferred_merchant_id,
          amount: amount,
          currency: currency,
          crc: payment_method.preferred_crc_key.to_s
        )
      }

      payload[:timeLimit] = payment_method.preferred_time_limit if payment_method.preferred_time_limit.present?
      payload[:channel] = payment_method.preferred_channel if payment_method.preferred_channel.present?
      payload[:method] = payment_method.preferred_method_id if payment_method.preferred_method_id.present?

      add_billing_address(payload)
      payload
    end

    def country_code
      order.bill_address&.country&.iso || order.ship_address&.country&.iso || "PL"
    end

    def add_billing_address(payload)
      address = order.bill_address
      return if address.nil?

      payload[:client] = address.full_name
      payload[:address] = address.address1.to_s
      payload[:zip] = address.zipcode.to_s
      payload[:city] = address.city.to_s
      payload[:phone] = address.phone.to_s
    end
  end
end
