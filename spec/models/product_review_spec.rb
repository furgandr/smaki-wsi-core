# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProductReview, type: :model do
  let(:order) { create(:completed_order_with_totals, shipment_state: "shipped") }
  let(:product) { order.line_items.first.product }
  let(:user) { order.user }

  before do
    order.shipments.update_all(shipped_at: Time.zone.now)
  end

  it "is valid with a shipped order and product from the order" do
    review = described_class.new(order:, product:, user:, rating: 5)
    expect(review).to be_valid
  end

  it "requires a rating between 1 and 5" do
    review = described_class.new(order:, product:, user:, rating: 0)
    expect(review).not_to be_valid
  end

  it "prevents duplicate reviews for the same product and user" do
    described_class.create!(order:, product:, user:, rating: 4)
    duplicate = described_class.new(order:, product:, user:, rating: 5)
    expect(duplicate).not_to be_valid
  end

  it "rejects products that are not part of the order" do
    other_product = create(:product)
    review = described_class.new(order:, product: other_product, user:, rating: 4)
    expect(review).not_to be_valid
  end

  it "rejects users that do not own the order" do
    other_user = create(:user)
    review = described_class.new(order:, product:, user: other_user, rating: 4)
    expect(review).not_to be_valid
  end
end
