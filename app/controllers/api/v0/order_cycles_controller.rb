# frozen_string_literal: true

module Api
  module V0
    class OrderCyclesController < Api::V0::BaseController
      include EnterprisesHelper
      include ApiActionCaching

      skip_authorization_check
      skip_before_action :authenticate_user, :ensure_api_key, only: [
        :taxons, :properties, :producer_properties
      ]

      caches_action :taxons, :properties, :producer_properties,
                    expires_in: CacheService::FILTERS_EXPIRY,
                    cache_path: proc { |controller|
                      "#{controller.request.url}-activation-fee-#{controller.activation_fee_cache_key}"
                    }

      def products
        return render_no_products if activation_fee_blocked?
        return render_no_products unless order_cycle.open?

        current_user = @current_api_user&.persisted? ? @current_api_user : nil
        current_user_enterprise_ids = current_user ? Enterprise.managed_by(current_user).pluck(:id) : []

        products = ProductsRenderer.new(
          distributor,
          order_cycle,
          customer,
          search_params,
          inventory_enabled:,
          variant_tag_enabled:,
          current_user: current_user,
          current_user_enterprise_ids: current_user_enterprise_ids
        ).products_json

        render plain: products
      rescue ProductsRenderer::NoProducts
        render_no_products
      end

      def taxons
        return render plain: "[]" if activation_fee_blocked?

        taxons = Spree::Taxon.
          joins(:products).
          where(spree_products: { id: distributed_products }).
          select('DISTINCT spree_taxons.*')

        render plain: ActiveModel::ArraySerializer.new(
          taxons, each_serializer: Api::TaxonSerializer
        ).to_json
      end

      def properties
        return render plain: "[]" if activation_fee_blocked?

        render plain: ActiveModel::ArraySerializer.new(
          product_properties, each_serializer: Api::PropertySerializer
        ).to_json
      end

      def producer_properties
        return render plain: "[]" if activation_fee_blocked?

        render plain: ActiveModel::ArraySerializer.new(
          load_producer_properties, each_serializer: Api::PropertySerializer
        ).to_json
      end

      private

      def render_no_products
        render status: :not_found, json: {}
      end


      def product_properties
        Spree::Property.
          joins(:products).
          where(spree_products: { id: distributed_products }).
          select('DISTINCT spree_properties.*')
      end

      def load_producer_properties
        producers = Enterprise.
          joins(:supplied_products).
          where(spree_products: { id: distributed_products })

        Spree::Property.
          joins(:producer_properties).
          where(producer_properties: { producer_id: producers }).
          select('DISTINCT spree_properties.*')
      end

      def search_params
        params.slice :q, :page, :per_page
      end

      def distributor
        @distributor ||= Enterprise.find_by(id: params[:distributor])
      end

      def order_cycle
        @order_cycle ||= OrderCycle.find_by(id: params[:id])
      end

      def customer
        @current_api_user&.customer_of(distributor) || nil
      end

      def distributed_products
        OrderCycles::DistributedProductsService.new(
          distributor, order_cycle, customer, inventory_enabled:, variant_tag_enabled:,
        ).products_relation.pluck(:id)
      end

      def inventory_enabled
        OpenFoodNetwork::FeatureToggle.enabled?(:inventory, distributor)
      end

      def variant_tag_enabled
        OpenFoodNetwork::FeatureToggle.enabled?(:variant_tag, distributor)
      end

      def activation_fee_blocked?
        owner = distributor&.owner
        return false if owner.nil?
        return false if @current_api_user&.admin? || @current_api_user == owner

        owner.activation_fee_required?
      end

      def activation_fee_cache_key
        activation_fee_blocked? ? "blocked" : "open"
      end
    end
  end
end
