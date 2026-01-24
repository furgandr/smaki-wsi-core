# frozen_string_literal: true

module ActivationFee
  class OrderService
    def initialize(user)
      @user = user
    end

    def call
      setup = ActivationFee::SetupService.new.call
      existing_order = existing_activation_fee_order

      if existing_order
        return existing_order if order_ready?(existing_order, setup)

        existing_order.empty!
        existing_order.update!(
          distributor: setup.enterprise,
          order_cycle: setup.order_cycle
        )
        existing_order.contents.add(setup.variant, 1)
        return existing_order
      end

      order = Spree::Order.create!(
        user: @user,
        created_by: @user,
        email: @user.email,
        distributor: setup.enterprise,
        order_cycle: setup.order_cycle,
        activation_fee_user_id: @user.id
      )

      order.contents.add(setup.variant, 1)
      order
    end

    private

    def existing_activation_fee_order
      Spree::Order
        .where(activation_fee_user_id: @user.id, completed_at: nil)
        .order(created_at: :desc)
        .first
    end

    def order_ready?(order, setup)
      return false unless order.distributor == setup.enterprise
      return false unless order.order_cycle == setup.order_cycle

      order.line_items.any? { |line_item| line_item.variant_id == setup.variant.id }
    end
  end
end
