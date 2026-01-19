# frozen_string_literal: true

require "przelewy24/client"
require "przelewy24/signature"

module Spree
  class Gateway
    class Przelewy24 < Gateway
      preference :merchant_id, :integer
      preference :pos_id, :integer
      preference :api_key, :string
      preference :crc_key, :string
      preference :language, :string, default: "pl"
      preference :test_mode, :boolean, default: false
      preference :channel, :integer
      preference :method_id, :integer
      preference :wait_for_result, :boolean, default: true
      preference :time_limit, :integer

      def external_gateway?
        true
      end

      def external_payment_url(options)
        return if options[:order].blank?

        Checkout::Przelewy24Redirect.new(self, options[:order]).call
      end

      def method_type
        "przelewy24"
      end

      def payment_profiles_supported?
        false
      end

      def client
        Przelewy24::Client.new(self)
      end

      def purchase(money, _source, gateway_options)
        payment = fetch_payment(gateway_options)
        return failure_response("Missing payment") if payment.nil?
        return failure_response("Missing P24 order id") if payment.response_code.blank?
        return failure_response("Missing session id") if payment.identifier.blank?

        amount = money.to_i
        currency = gateway_options[:currency]
        verify_payload = {
          merchantId: preferred_merchant_id,
          posId: preferred_pos_id || preferred_merchant_id,
          sessionId: payment.identifier,
          amount: amount,
          currency: currency,
          orderId: payment.response_code.to_i,
          sign: Przelewy24::Signature.verify(
            session_id: payment.identifier,
            order_id: payment.response_code.to_i,
            amount: amount,
            currency: currency,
            crc: preferred_crc_key.to_s
          )
        }

        response = client.verify(verify_payload)
        if response[:status] == 200 && response.dig(:body, "responseCode").to_i.zero?
          ActiveMerchant::Billing::Response.new(true, "P24 verified", {}, authorization: payment.response_code)
        else
          failure_response("P24 verification failed")
        end
      rescue StandardError => e
        failure_response(e.message)
      end

      private

      def failure_response(message)
        ActiveMerchant::Billing::Response.new(false, message)
      end

      def fetch_payment(gateway_options)
        order_number = gateway_options[:order_id].to_s.split("-").first
        order = Spree::Order.find_by(number: order_number)
        return if order.nil?

        order.payments.where(payment_method_id: id).order(:created_at).last
      end
    end
  end
end
