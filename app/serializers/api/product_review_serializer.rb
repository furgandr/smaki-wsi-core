# frozen_string_literal: true

module Api
  class ProductReviewSerializer < ActiveModel::Serializer
    attributes :id, :rating, :comment, :created_at, :author_name, :seller_response,
               :seller_can_reply

    def seller_response
      object.seller_response
    end

    def seller_can_reply
      user = options[:current_user]
      return false unless user&.persisted?

      return false unless object.response_window_open?

      supplier_id = object.product&.supplier_id
      supplier_id ||= object.product&.variants&.first&.supplier_id
      supplier_id ||= Spree::Variant.where(product_id: object.product_id).limit(1).pick(:supplier_id)
      return false if supplier_id.blank?

      enterprise_ids = options[:current_user_enterprise_ids]
      enterprise_ids ||= Enterprise.managed_by(user).pluck(:id)
      enterprise_ids.include?(supplier_id)
    end

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
