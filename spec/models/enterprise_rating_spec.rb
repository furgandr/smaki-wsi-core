# frozen_string_literal: true

require "spec_helper"

RSpec.describe EnterpriseRating, type: :model do
  let(:order) { create(:completed_order_with_totals, shipment_state: "shipped") }
  let(:supplier) { order.line_items.first.supplier }
  let(:user) { order.user }

  it "is valid with a completed order and supplier from the order" do
    rating = described_class.new(order:, enterprise: supplier, user:, rating: 4)
    expect(rating).to be_valid
  end

  it "requires a rating between 1 and 5" do
    rating = described_class.new(order:, enterprise: supplier, user:, rating: 6)
    expect(rating).not_to be_valid
  end

  it "prevents duplicate ratings for the same order and seller" do
    described_class.create!(order:, enterprise: supplier, user:, rating: 5)
    duplicate = described_class.new(order:, enterprise: supplier, user:, rating: 4)
    expect(duplicate).not_to be_valid
  end

  it "rejects sellers that are not part of the order" do
    other_supplier = create(:supplier_enterprise)
    rating = described_class.new(order:, enterprise: other_supplier, user:, rating: 3)
    expect(rating).not_to be_valid
  end

  it "allows rating the distributor for the order" do
    distributor = order.distributor
    rating = described_class.new(order:, enterprise: distributor, user:, rating: 5)
    expect(rating).to be_valid
  end

  it "rejects users that do not own the order" do
    other_user = create(:user)
    rating = described_class.new(order:, enterprise: supplier, user: other_user, rating: 3)
    expect(rating).not_to be_valid
  end
end
