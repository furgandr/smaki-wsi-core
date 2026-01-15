# frozen_string_literal: true

require "spec_helper"

RSpec.describe Przelewy24::Signature do
  describe ".register" do
    it "generates a sha384 signature for register payload" do
      payload = {
        sessionId: "sess-1",
        merchantId: 123,
        amount: 1000,
        currency: "PLN",
        crc: "crc_key"
      }

      expected = OpenSSL::Digest::SHA384.hexdigest(
        JSON.generate(payload, ascii_only: false)
      )

      actual = described_class.register(
        session_id: "sess-1",
        merchant_id: 123,
        amount: 1000,
        currency: "PLN",
        crc: "crc_key"
      )

      expect(actual).to eq(expected)
    end
  end

  describe ".verify" do
    it "generates a sha384 signature for verify payload" do
      payload = {
        sessionId: "sess-1",
        orderId: 999,
        amount: 1000,
        currency: "PLN",
        crc: "crc_key"
      }

      expected = OpenSSL::Digest::SHA384.hexdigest(
        JSON.generate(payload, ascii_only: false)
      )

      actual = described_class.verify(
        session_id: "sess-1",
        order_id: 999,
        amount: 1000,
        currency: "PLN",
        crc: "crc_key"
      )

      expect(actual).to eq(expected)
    end
  end
end
