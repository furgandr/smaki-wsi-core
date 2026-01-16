# frozen_string_literal: true

module Spree
  class EnterpriseRatingsController < ::BaseController
    before_action :load_order
    before_action :require_user
    before_action :ensure_order_access
    before_action :ensure_order_shipped
    before_action :load_enterprise_rating, only: :update

    def create
      rating = EnterpriseRating.new(rating_params.merge(order: @order, user: spree_current_user))

      if rating.save
        EnterpriseRatingMailer.seller_rating_received(rating.id).deliver_later
        flash[:success] = I18n.t("ratings.flash.saved")
      else
        flash[:error] = rating.errors.full_messages.to_sentence
      end

      redirect_to main_app.order_path(@order)
    end

    def update
      if @enterprise_rating.update(rating_params)
        flash[:success] = I18n.t("ratings.flash.updated")
      else
        flash[:error] = @enterprise_rating.errors.full_messages.to_sentence
      end

      redirect_to main_app.order_path(@order)
    end

    private

    def load_order
      @order = Spree::Order.find_by!(number: params[:order_id])
    end

    def load_enterprise_rating
      @enterprise_rating = @order.enterprise_ratings.find(params[:id])
    end

    def require_user
      return if spree_current_user

      flash[:error] = I18n.t("ratings.errors.login_required")
      redirect_to main_app.root_path
    end

    def ensure_order_access
      return if @order.user_id == spree_current_user.id

      render status: :forbidden, plain: I18n.t("errors.unauthorized.message")
    end

    def ensure_order_shipped
      return if @order.shipped?

      flash[:error] = I18n.t("ratings.errors.order_not_shipped")
      redirect_to main_app.order_path(@order)
    end

    def rating_params
      params.require(:enterprise_rating).permit(:enterprise_id, :rating, :comment)
    end
  end
end
