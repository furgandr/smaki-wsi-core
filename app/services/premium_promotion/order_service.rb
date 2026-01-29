# frozen_string_literal: true

module PremiumPromotion
  class OrderService
    def initialize(user, supplier:, distributor:, promotion_plan:, product_ids:)
      @user = user
      @supplier = supplier
      @distributor = distributor
      @promotion_plan = promotion_plan
      @product_ids = Array(product_ids).map(&:to_i).reject(&:zero?)
    end

    def call
      setup = PremiumPromotion::SetupService.new.call
      plan = @promotion_plan.is_a?(PromotionPlan) ? @promotion_plan : PromotionPlan.find(@promotion_plan)
      variant = Spree::Variant.find_by!(sku: plan.sku)

      ActiveRecord::Base.transaction do
        order = Spree::Order.create!(
          user: @user,
          created_by: @user,
          email: @user.email,
          distributor: setup.enterprise,
          order_cycle: setup.order_cycle
        )

        order.contents.add(variant, 1)

        promotion = SellerPromotion.new(
          supplier: @supplier,
          distributor: @distributor,
          promotion_plan: plan,
          order:
        )
        promotion.product_ids = @product_ids
        promotion.save!

        order
      end
    end
  end
end
