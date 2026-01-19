# frozen_string_literal: true

require "json"
require "net/http"

module Przelewy24
  class Client
    def initialize(gateway)
      @gateway = gateway
    end

    def register(payload)
      post_json("/api/v1/transaction/register", payload)
    end

    def verify(payload)
      put_json("/api/v1/transaction/verify", payload)
    end

    def base_url
      gateway.preferred_test_mode ? "https://sandbox.przelewy24.pl" : "https://secure.przelewy24.pl"
    end

    private

    attr_reader :gateway

    def post_json(path, payload)
      request_json(Net::HTTP::Post.new(uri(path)), payload)
    end

    def put_json(path, payload)
      request_json(Net::HTTP::Put.new(uri(path)), payload)
    end

    def uri(path)
      URI.join(base_url, path)
    end

    def request_json(request, payload)
      request.basic_auth(gateway.preferred_merchant_id.to_s, gateway.preferred_api_key.to_s)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload, ascii_only: false)

      response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      parse_response(response)
    end

    def parse_response(response)
      body = response.body.to_s
      json = body.empty? ? {} : JSON.parse(body)
      { status: response.code.to_i, body: json }
    rescue JSON::ParserError
      { status: response.code.to_i, body: { "raw" => body } }
    end
  end
end
