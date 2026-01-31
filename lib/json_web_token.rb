# frozen_string_literal: true

module JsonWebToken
  ALGORITHM = "HS256"

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
    decoded.first
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end
