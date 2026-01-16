# frozen_string_literal: true

module Api
  class ProductReviewSerializer < ActiveModel::Serializer
    attributes :rating, :comment, :created_at, :author_name

    def author_name
      order = object.order
      user = object.user || order&.user
      first = order&.bill_address&.firstname || user&.first_name || user&.firstname
      last = order&.bill_address&.lastname || user&.last_name || user&.lastname

      if first.present?
        masked_last = mask_last_name(last)
        [first, masked_last].reject(&:blank?).join(" ").strip
      else
        label = user&.login.presence || user&.email.to_s.split("@").first
        mask_label(label)
      end
    end

    def mask_label(label)
      return "" if label.to_s.strip.empty?

      text = label.to_s
      return "#{text.first}***" if text.length < 4

      "#{text.first(2)}***#{text.last(2)}"
    end

    def mask_last_name(last_name)
      return "" if last_name.to_s.strip.empty?

      text = last_name.to_s
      visible = text[-2, 2] || text
      ("*" * [text.length - 2, 0].max) + visible
    end
  end
end
