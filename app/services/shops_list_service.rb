# frozen_string_literal: true

class ShopsListService
  # shops that are ready for checkout, and have an order cycle that is currently open
  def open_shops
    shops = shops_list.
      ready_for_checkout.
      distributors_with_active_order_cycles

    activation_fee_filtered(shops)
  end

  # shops that are either not ready for checkout, or don't have an open order cycle; the inverse of
  # #open_shops
  def closed_shops
    shops_list.where.not(id: open_shops.reselect("enterprises.id"))
  end

  private

  def shops_list
    Enterprise
      .activated
      .visible
      .is_distributor
      .includes(address: [:state, :country])
      .includes(:properties)
      .includes(supplied_products: :properties)
      .with_attached_promo_image
      .with_attached_logo
  end

  def activation_fee_filtered(shops)
    return shops unless Spree::Config[:activation_fee_enabled]

    free_limit = Spree::Config[:activation_fee_free_limit].to_i
    free_user_ids = if free_limit.positive?
                      Spree::User.order(:created_at, :id).limit(free_limit).pluck(:id)
                    else
                      []
                    end

    conditions = [
      "spree_users.admin = :true OR spree_users.activation_fee_exempt = :true OR " \
        "spree_users.activation_fee_paid_at IS NOT NULL",
      { true: true }
    ]
    if free_user_ids.any?
      conditions[0] += " OR spree_users.id IN (:free_user_ids)"
      conditions[1][:free_user_ids] = free_user_ids
    end

    shops.joins(:owner).where(conditions)
  end
end
