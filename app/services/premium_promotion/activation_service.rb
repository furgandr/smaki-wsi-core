# frozen_string_literal: true

module PremiumPromotion
  class ActivationService
    def initialize(order)
      @order = order
    end

    def call
      pending_promotions.find_each do |promotion|
        activate_promotion(promotion)
      end
    end

    private

    def pending_promotions
      SellerPromotion.pending.where(order_id: @order.id)
    end

    def activate_promotion(promotion)
      now = Time.current
      last_end = SellerPromotion
        .where(supplier_id: promotion.supplier_id, distributor_id: promotion.distributor_id)
        .where(status: ["active", "scheduled"])
        .where.not(id: promotion.id)
        .maximum(:ends_at)

      starts_at = last_end.present? && last_end > now ? last_end : now
      ends_at = starts_at + promotion.promotion_plan.duration_days.days
      status = starts_at > now ? "scheduled" : "active"

      promotion.update!(
        starts_at:,
        ends_at:,
        status:
      )
    end
  end
end
