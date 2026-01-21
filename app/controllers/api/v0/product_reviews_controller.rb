# frozen_string_literal: true

module Api
  module V0
    class ProductReviewsController < Api::V0::BaseController
      skip_authorization_check

      before_action :load_review
      before_action :ensure_seller_access

      def response
        if @review.update(seller_response_params.merge(seller_response_updated_at: Time.current,
                                                      seller_responder_id: current_api_user.id))
          render json: Api::ProductReviewSerializer.new(
            @review,
            current_user: current_api_user,
            current_user_enterprise_ids: managed_enterprise_ids
          ).serializable_hash
        else
          invalid_resource!(@review)
        end
      end

      private

      def load_review
        @review = ProductReview.find(params[:id])
      end

      def ensure_seller_access
        return if seller_can_reply?

        render json: { error: I18n.t("errors.unauthorized.message") }, status: :forbidden
      end

      def seller_can_reply?
        return false unless current_api_user&.persisted?

        supplier_id = @review.product&.supplier_id
        return false if supplier_id.blank?

        managed_enterprise_ids.include?(supplier_id)
      end

      def managed_enterprise_ids
        @managed_enterprise_ids ||= Enterprise.managed_by(current_api_user).pluck(:id)
      end

      def seller_response_params
        params.require(:product_review).permit(:seller_response)
      end
    end
  end
end
