# frozen_string_literal: true

module PremiumPromotion
  class SetupService
    SKU_30 = "PREMIUM-PROMO-30"
    SKU_60 = "PREMIUM-PROMO-60"

    ENTERPRISE_NAME = "Premium Promotion Platform"
    ENTERPRISE_PERMALINK = "premium-promotion-platform"
    SHIPPING_CATEGORY_NAME = "Premium Promotion"
    SHIPPING_METHOD_NAME = "Premium Promotion (No Shipping)"
    TAX_CATEGORY_NAME = "Premium Promotion"
    TAXON_NAME = "Premium Promotion"
    ORDER_CYCLE_NAME = "Premium Promotion"
    STOCK_LOCATION_NAME = "Premium Promotion"

    PLAN_DEFINITIONS = [
      { name: "Premium promotion 30 days", sku: SKU_30, duration_days: 30, price_cents: 2990 },
      { name: "Premium promotion 60 days", sku: SKU_60, duration_days: 60, price_cents: 4990 }
    ].freeze

    Result = Struct.new(:enterprise, :order_cycle, :plans, :plan_variants, keyword_init: true)

    def call
      enterprise = find_or_create_enterprise
      shipping_category = find_or_create_shipping_category
      shipping_method = find_or_create_shipping_method(shipping_category, enterprise)
      attach_payment_methods(enterprise)
      tax_category = find_or_create_tax_category
      taxon = find_or_create_taxon
      stock_location = find_or_create_stock_location

      plans = PLAN_DEFINITIONS.map { |definition| find_or_create_plan(definition) }
      plan_variants = plans.index_with do |plan|
        variant = find_or_create_product(enterprise, shipping_category, tax_category, taxon, plan)
        ensure_stock_item(variant, stock_location)
        variant
      end

      order_cycle = find_or_create_order_cycle(enterprise, plan_variants.values)
      ensure_distributor_shipping_method(enterprise, shipping_method)

      Result.new(
        enterprise:,
        order_cycle:,
        plans:,
        plan_variants:
      )
    end

    private

    def find_or_create_enterprise
      Enterprise.find_by(permalink: ENTERPRISE_PERMALINK) || create_enterprise
    end

    def create_enterprise
      owner = Spree::User.admin.first || Spree::User.first
      raise "Premium promotion requires an admin user to own the platform enterprise." unless owner

      address = build_enterprise_address

      Enterprise.create!(
        name: ENTERPRISE_NAME,
        permalink: ENTERPRISE_PERMALINK,
        sells: "own",
        is_primary_producer: true,
        visible: "hidden",
        owner:,
        address:
      )
    end

    def build_enterprise_address
      country = DefaultCountry.country
      state = country&.states&.first

      Spree::Address.new(
        firstname: "Premium",
        lastname: "Promotion",
        company: ENTERPRISE_NAME,
        address1: "Premium Promotion Street 1",
        city: "Promotion City",
        zipcode: "00-000",
        phone: "000000000",
        country:,
        state:,
        state_name: state ? nil : country&.states_required ? "N/A" : nil
      )
    end

    def find_or_create_plan(definition)
      plan = PromotionPlan.find_or_initialize_by(sku: definition[:sku])
      plan.name = definition[:name]
      plan.duration_days = definition[:duration_days]
      plan.price_cents = definition[:price_cents]
      plan.currency = CurrentConfig.get(:currency)
      plan.active = true
      plan.save!
      plan
    end

    def find_or_create_shipping_category
      Spree::ShippingCategory.find_or_create_by!(name: SHIPPING_CATEGORY_NAME)
    end

    def find_or_create_shipping_method(shipping_category, enterprise)
      method = Spree::ShippingMethod.find_or_initialize_by(name: SHIPPING_METHOD_NAME)
      method.display_on = nil
      method.require_ship_address = false if method.respond_to?(:require_ship_address=)
      method.shipping_categories = [shipping_category]
      method.distributors = (method.distributors.to_a + [enterprise]).uniq
      method.save!
      method
    end

    def ensure_distributor_shipping_method(enterprise, shipping_method)
      DistributorShippingMethod.find_or_create_by!(
        distributor: enterprise,
        shipping_method:
      )
    end

    def attach_payment_methods(enterprise)
      Spree::PaymentMethod.available.select(&:configured?).each do |payment_method|
        DistributorPaymentMethod.find_or_create_by!(
          distributor: enterprise,
          payment_method:
        )
      end
    end

    def find_or_create_tax_category
      Spree::TaxCategory.find_or_create_by!(name: TAX_CATEGORY_NAME)
    end

    def find_or_create_taxon
      Spree::Taxon.find_or_create_by!(name: TAXON_NAME)
    end

    def find_or_create_stock_location
      Spree::StockLocation.find_or_create_by!(name: STOCK_LOCATION_NAME) do |location|
        country = DefaultCountry.country
        state = country&.states&.first
        location.active = true
        location.address1 = "Premium Promotion Street 1"
        location.city = "Promotion City"
        location.zipcode = "00-000"
        location.phone = "000000000"
        location.country = country
        location.state = state if state
      end
    end

    def find_or_create_product(enterprise, shipping_category, tax_category, taxon, plan)
      variant = Spree::Variant.find_by(sku: plan.sku)
      if variant
        ensure_variant_price(variant, plan)
        return variant
      end

      product = Spree::Product.create!(
        name: plan.name,
        price: plan.price_cents / 100.0,
        display_as: plan.name,
        supplier_id: enterprise.id,
        primary_taxon_id: taxon.id,
        shipping_category_id: shipping_category.id,
        tax_category_id: tax_category.id,
        variant_unit: "items",
        variant_unit_name: "item",
        unit_value: 1
      )

      variant = product.variants.first
      variant.update!(sku: plan.sku)
      ensure_variant_price(variant, plan)

      variant
    end

    def ensure_stock_item(variant, stock_location)
      Spree::StockItem.find_or_create_by!(
        variant:,
        stock_location:
      ) do |stock_item|
        stock_item.count_on_hand = 1_000_000
        stock_item.backorderable = true
      end
    end

    def find_or_create_order_cycle(enterprise, variants)
      order_cycle = OrderCycle.find_or_create_by!(
        name: ORDER_CYCLE_NAME,
        coordinator: enterprise
      ) do |cycle|
        cycle.orders_open_at = 1.day.ago
        cycle.orders_close_at = 100.years.from_now
      end

      ensure_exchanges(order_cycle, enterprise, variants)

      order_cycle
    end

    def ensure_exchanges(order_cycle, enterprise, variants)
      incoming = Exchange.find_or_create_by!(
        order_cycle:,
        incoming: true,
        sender: enterprise,
        receiver: enterprise
      )
      outgoing = Exchange.find_or_create_by!(
        order_cycle:,
        incoming: false,
        sender: enterprise,
        receiver: enterprise
      )

      variants.each do |variant|
        ExchangeVariant.find_or_create_by!(exchange: incoming, variant:)
        ExchangeVariant.find_or_create_by!(exchange: outgoing, variant:)
      end
    end

    def ensure_variant_price(variant, plan)
      price_amount = plan.price_cents / 100.0
      return if variant.price.to_d == price_amount.to_d

      variant.price = price_amount
      variant.save!
    end
  end
end
