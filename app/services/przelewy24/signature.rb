# frozen_string_literal: true

require "json"
require "openssl"

module Przelewy24
  module Signature
    module_function

    def register(session_id:, merchant_id:, amount:, currency:, crc:)
      payload = {
        sessionId: session_id,
        merchantId: merchant_id,
        amount: amount,
        currency: currency,
        crc: crc
      }
      digest(payload)
    end

    def verify(session_id:, order_id:, amount:, currency:, crc:)
      payload = {
        sessionId: session_id,
        orderId: order_id,
        amount: amount,
        currency: currency,
        crc: crc
      }
      digest(payload)
    end

    def notification(merchant_id:, pos_id:, session_id:, amount:, origin_amount:, currency:, order_id:,
                     method_id:, statement:, crc:)
      payload = {
        merchantId: merchant_id,
        posId: pos_id,
        sessionId: session_id,
        amount: amount,
        originAmount: origin_amount,
        currency: currency,
        orderId: order_id,
        methodId: method_id,
        statement: statement.to_s,
        crc: crc
      }
      digest(payload)
    end

    def digest(payload)
      json = JSON.generate(payload, ascii_only: false)
      OpenSSL::Digest::SHA384.hexdigest(json)
    end
  end
end
