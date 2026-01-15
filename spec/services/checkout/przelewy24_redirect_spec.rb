# frozen_string_literal: true

require "spec_helper"

RSpec.describe Checkout::Przelewy24Redirect do
  let(:order) { create(:order_ready_for_payment) }
  let(:payment_method) do
    create(:przelewy24_payment_method, distributors: [order.distributor])
  end
  let(:client) { instance_double(Przelewy24::Client) }

  before do
    allow(payment_method).to receive(:client).and_return(client)
    allow(client).to receive(:register).and_return(
      status: 200,
      body: { "responseCode" => 0, "data" => { "token" => "tok_123" } }
    )
  end

  it "returns redirect URL and stores session identifier" do
    url = described_class.new(payment_method, order).call

    expect(url).to eq("https://sandbox.przelewy24.pl/trnRequest/tok_123")
    payment = order.payments.where(payment_method_id: payment_method.id).last
    expect(payment.identifier).to start_with("ofn-#{order.number}-")
  end
end
