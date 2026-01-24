# frozen_string_literal: true

require 'open_food_network/permissions'

module Spree
  module Admin
    class SellerPromotionsController < ::Admin::ResourceController
      before_action :load_form_data, only: [:new, :edit, :create, :update]
      before_action :ensure_authorized_enterprises, only: [:create, :update]

      def show
      end

      private

      def collection
        super.includes(:supplier, :distributor, :promotion_plan, :products)
          .order(created_at: :desc)
      end

      def permitted_resource_params
        permitted = [:supplier_id, :distributor_id, :promotion_plan_id, product_ids: []]

        if spree_current_user.admin?
          permitted += [:status, :starts_at, :ends_at]
        end

        params.require(:seller_promotion).permit(permitted)
      end

      def load_form_data
        PremiumPromotion::SetupService.new.call
        permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
        @suppliers = permissions.managed_product_enterprises.by_name
        @distributors = permissions.managed_enterprises.by_name
        @promotion_plans = PromotionPlan.active.order(:duration_days)
        @products = Spree::Product
          .joins(:variants)
          .where(spree_variants: { supplier_id: @suppliers.select(:id) })
          .distinct
          .order(:name)
      end

      def ensure_authorized_enterprises
        return if spree_current_user.admin?

        supplier_id = permitted_resource_params[:supplier_id]
        distributor_id = permitted_resource_params[:distributor_id]

        return if @suppliers.exists?(id: supplier_id) && @distributors.exists?(id: distributor_id)

        raise CanCan::AccessDenied
      end
    end
  end
end
