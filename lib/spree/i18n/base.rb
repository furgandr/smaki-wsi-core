# frozen_string_literal: true

module Spree
  module ViewContext
    def self.context=(context)
      @context = context
    end

    def self.context
      @context
    end

    def view_context
      super.tap do |context|
        Spree::ViewContext.context = context
      end
    end
  end
end

# Zeitwerk expects this constant to match the file path.
module Spree
  module I18n
    class << self
      def method_missing(name, *args, &block)
        return ::I18n.public_send(name, *args, &block) if ::I18n.respond_to?(name)

        super
      end

      def respond_to_missing?(name, include_private = false)
        ::I18n.respond_to?(name, include_private) || super
      end
    end

    module Base
    end
  end
end
