# frozen_string_literal: true

module Spree
  class ProductReviewsController < ::BaseController
    before_action :load_order
    before_action :require_user
    before_action :ensure_order_access
    before_action :ensure_order_shipped
    before_action :ensure_review_window
    before_action :load_product_review, only: :update
    before_action :load_product

    def create
      review = ProductReview.find_or_initialize_by(product: @product, user: spree_current_user)
      review.assign_attributes(review_params.merge(order: @order))

      if review.save
        flash[:success] = I18n.t("product_reviews.flash.saved")
      else
        flash[:error] = review.errors.full_messages.to_sentence
      end

      redirect_to main_app.order_path(@order)
    end

    def update
      if @product_review.update(review_params.merge(order: @order))
        flash[:success] = I18n.t("product_reviews.flash.updated")
      else
        flash[:error] = @product_review.errors.full_messages.to_sentence
      end

      redirect_to main_app.order_path(@order)
    end

    private

    def load_order
      @order = Spree::Order.find_by!(number: params[:order_id])
    end

    def load_product_review
      @product_review = ProductReview.find(params[:id])
    end

    def load_product
      @product =
        if @product_review
          @product_review.product
        else
          Spree::Product.find(params[:product_id])
        end
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

    def ensure_review_window
      return if @order.review_window_open?

      flash[:error] = I18n.t("ratings.errors.review_window_closed")
      redirect_to main_app.order_path(@order)
    end

    def review_params
      params.require(:product_review).permit(:rating, :comment)
    end
  end
end
