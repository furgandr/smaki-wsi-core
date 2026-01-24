# frozen_string_literal: true

class ActivationFeesController < BaseController
  before_action :authenticate_spree_user!
  before_action :ensure_activation_fee_required

  def show
    @activation_fee_amount = Spree::Money.new(
      Spree::Config.activation_fee_amount_value,
      currency: CurrentConfig.get(:currency)
    )
  end

  def create
    order = ActivationFee::OrderService.new(spree_current_user).call

    if session[:order_id].present? && session[:order_id] != order.id
      session[:previous_order_id] = session[:order_id]
    end
    session[:order_id] = order.id

    redirect_to checkout_step_path(:details)
  end

  private

  def ensure_activation_fee_required
    return if spree_current_user.activation_fee_required?

    redirect_to spree.admin_dashboard_path
  end
end
