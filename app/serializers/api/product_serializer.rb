# frozen_string_literal: true

require "open_food_network/scope_variant_to_hub"

class Api::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :meta_keywords, :rating_average, :rating_count, :recent_reviews
  attributes :group_buy, :notes, :description, :description_html
  attributes :properties_with_values

  has_many :variants, serializer: Api::VariantSerializer

  has_one :image, serializer: Api::ImageSerializer

  # return an unformatted descripton
  def description
    sanitizer.strip_content(object.description)
  end

  # return a sanitized html description
  def description_html
    trix_sanitizer.sanitize_content(object.description)
  end

  def properties_with_values
    object.properties_including_inherited
  end

  def variants
    options[:variants][object.id] || []
  end

  def rating_average
    object.rating_average
  end

  def rating_count
    object.rating_count
  end

  def recent_reviews
    reviews = object.product_reviews.active_for_stats
      .includes(order: :bill_address)
      .where.not(comment: [nil, ""])
      .order(created_at: :desc)

    reviews.map do |review|
      Api::ProductReviewSerializer.new(
        review,
        current_user: instance_options[:current_user],
        current_user_enterprise_ids: instance_options[:current_user_enterprise_ids]
      ).serializable_hash
    end
  end

  private

  def sanitizer
    @sanitizer ||= ContentSanitizer.new
  end

  def trix_sanitizer
    @trix_sanitizer ||= TrixSanitizer.new
  end
end
