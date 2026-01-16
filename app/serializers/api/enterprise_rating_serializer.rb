# frozen_string_literal: true

module Api
  class EnterpriseRatingSerializer < ActiveModel::Serializer
    attributes :rating, :comment, :created_at, :author_name, :excluded_from_stats, :excluded_reason

    def author_name
      user = object.user || object.order&.user
      label = user&.login.presence || user&.email.to_s.split("@").first
      mask_label(label)
    end

    def mask_label(label)
      return "" if label.to_s.strip.empty?

      text = label.to_s
      return "#{text.first}***" if text.length < 4

      "#{text.first(2)}***#{text.last(2)}"
    end
  end
end
