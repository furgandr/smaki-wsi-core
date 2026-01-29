# frozen_string_literal: true

require 'open_food_network/permissions'

class PremiumPromotionsController < BaseController
  before_action :authenticate_spree_user!
  before_action :load_permissions
  before_action :load_form_data, only: [:show, :create]

  def show
  end

  def create
    supplier = @suppliers.find(premium_promotion_params[:supplier_id])
    distributor = @distributors.find(premium_promotion_params[:distributor_id])
    plan = PromotionPlan.active.find(premium_promotion_params[:promotion_plan_id])

    order = PremiumPromotion::OrderService.new(
      spree_current_user,
      supplier:,
      distributor:,
      promotion_plan: plan,
      product_ids: premium_promotion_params[:product_ids]
    ).call

    if session[:order_id].present? && session[:order_id] != order.id
      session[:previous_order_id] = session[:order_id]
    end
    session[:order_id] = order.id

    redirect_to checkout_step_path(:details)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = t("premium_promotions.errors.invalid_selection")
    render :show
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.record.errors.full_messages.to_sentence
    render :show
  end

  private

  def load_permissions
    @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
  end

  def load_form_data
    PremiumPromotion::SetupService.new.call
    @promotion_plans = PromotionPlan.active.order(:duration_days)
    @suppliers = @permissions.managed_product_enterprises.by_name
    @distributors = @permissions.managed_enterprises.by_name
    @products = Spree::Product
      .joins(:variants)
      .where(spree_variants: { supplier_id: @suppliers.select(:id) })
      .distinct
      .order(:name)
  end

  def premium_promotion_params
    params.require(:premium_promotion)
      .permit(:supplier_id, :distributor_id, :promotion_plan_id, product_ids: [])
  end
end
