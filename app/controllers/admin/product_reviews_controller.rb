# frozen_string_literal: true

module Admin
  class ProductReviewsController < Spree::Admin::BaseController
    before_action :require_admin
    before_action :load_review, only: [:remove, :restore, :exclude, :include]

    def index
      @reviews = ProductReview
        .includes(:product, :user, order: :bill_address)
        .order(created_at: :desc)
    end

    def remove
      @review.update(
        removed_at: Time.zone.now,
        removal_reason: params[:removal_reason].to_s.strip.presence
      )
      flash[:success] = t("admin.product_reviews.flash.removed")
      redirect_back fallback_location: main_app.admin_product_reviews_path
    end

    def restore
      @review.update(removed_at: nil, removal_reason: nil)
      flash[:success] = t("admin.product_reviews.flash.restored")
      redirect_back fallback_location: main_app.admin_product_reviews_path
    end

    def exclude
      @review.update(
        excluded_from_stats: true,
        excluded_reason: params[:excluded_reason].to_s.strip.presence
      )
      flash[:success] = t("admin.product_reviews.flash.excluded")
      redirect_back fallback_location: main_app.admin_product_reviews_path
    end

    def include
      @review.update_columns(
        excluded_from_stats: false,
        excluded_reason: nil,
        updated_at: Time.zone.now
      )
      flash[:success] = t("admin.product_reviews.flash.included")
      redirect_back fallback_location: main_app.admin_product_reviews_path
    end

    private

    def load_review
      @review = ProductReview.find(params[:id])
    end

    def require_admin
      return if spree_current_user&.admin?

      raise CanCan::AccessDenied
    end
  end
end
