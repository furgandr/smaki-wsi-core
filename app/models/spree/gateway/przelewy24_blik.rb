# frozen_string_literal: true

module Spree
  class Gateway
    class Przelewy24Blik < Przelewy24
      preference :channel, :integer, default: 8192

      def method_type
        "przelewy24_blik"
      end
    end
  end
end
