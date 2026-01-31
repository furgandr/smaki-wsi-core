# frozen_string_literal: true

# Zeitwerk expects this constant to match the file path.
module Spree
  module I18n
    module Initializer
    end
  end
end

ApplicationController.include(Spree::ViewContext)
