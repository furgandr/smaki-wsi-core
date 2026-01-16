# frozen_string_literal: true

module Admin
  class EnterpriseRatingsController < Spree::Admin::BaseController
    before_action :load_rating, only: [:remove, :restore, :exclude, :include, :request_removal]
    before_action :require_admin, only: [:remove, :restore, :exclude, :include]
    before_action :require_admin_or_enterprise_user, only: [:index]

    def index
      @ratings = base_scope
    end

    def remove
      @rating.update(
        removed_at: Time.zone.now,
        removal_reason: params[:removal_reason].to_s.strip.presence
      )
      flash[:success] = t("admin.enterprise_ratings.flash.removed")
      redirect_back fallback_location: main_app.admin_enterprise_ratings_path
    end

    def restore
      @rating.update(removed_at: nil, removal_reason: nil)
      flash[:success] = t("admin.enterprise_ratings.flash.restored")
      redirect_back fallback_location: main_app.admin_enterprise_ratings_path
    end

    def exclude
      @rating.update(
        excluded_from_stats: true,
        excluded_reason: params[:excluded_reason].to_s.strip.presence
      )
      flash[:success] = t("admin.enterprise_ratings.flash.excluded")
      redirect_back fallback_location: main_app.admin_enterprise_ratings_path
    end

    def include
      @rating.update_columns(
        excluded_from_stats: false,
        excluded_reason: nil,
        updated_at: Time.zone.now
      )
      flash[:success] = t("admin.enterprise_ratings.flash.included")
      redirect_back fallback_location: main_app.admin_enterprise_ratings_path
    end

    def request_removal
      if @rating.request_removal!(spree_current_user)
        flash[:success] = t("admin.enterprise_ratings.flash.removal_requested")
      else
        flash[:error] = t("admin.enterprise_ratings.flash.removal_request_denied")
      end

      redirect_back fallback_location: main_app.admin_enterprise_ratings_path
    end

    private

    def base_scope
      scope = EnterpriseRating
        .includes(:enterprise, :user, order: :bill_address)
        .order(created_at: :desc)

      return scope if spree_current_user.admin?

      scope.where(enterprise_id: spree_current_user.enterprises.select(:id))
    end

    def load_rating
      @rating = EnterpriseRating.find(params[:id])
    end

    def require_admin
      return if spree_current_user.admin?

      raise CanCan::AccessDenied
    end

    def require_admin_or_enterprise_user
      return if spree_current_user.admin? || spree_current_user.enterprises.any?

      raise CanCan::AccessDenied
    end
  end
end
