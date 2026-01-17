# frozen_string_literal: true

module Api
  class UncachedEnterpriseSerializer < ActiveModel::Serializer
    include SerializerHelper

    attributes :orders_close_at, :current_order_cycle_id, :active, :rating_average, :rating_count,
               :recommendation_percent

    def orders_close_at
      options[:data].earliest_closing_times[object.id]&.to_time
    end

    def active
      options[:data].active_distributor_ids&.include? object.id
    end

    def current_order_cycle_id
      options[:data].current_order_cycle_ids[object.id]
    end

    def rating_average
      object.rating_average
    end

    def rating_count
      object.rating_count
    end

    def recommendation_percent
      object.recommendation_percent
    end
  end
end
