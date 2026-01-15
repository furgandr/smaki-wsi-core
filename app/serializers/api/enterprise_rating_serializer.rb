# frozen_string_literal: true

module Api
  class EnterpriseRatingSerializer < ActiveModel::Serializer
    attributes :rating, :comment, :created_at, :author_name

    def author_name
      address = object.order&.bill_address
      return "" unless address

      "#{address.firstname} #{address.lastname}".strip
    end
  end
end
