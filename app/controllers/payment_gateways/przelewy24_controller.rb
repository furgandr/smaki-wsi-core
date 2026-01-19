# frozen_string_literal: true

module PaymentGateways
  class Przelewy24Controller < BaseController
    include OrderCompletion

    skip_before_action :verify_authenticity_token, only: :status
    before_action :load_return_order, only: :return

    def return
      payment = Orders::FindPaymentService.new(@order).last_payment
      unless payment&.payment_method.is_a?(Spree::Gateway::Przelewy24)
        flash[:error] = I18n.t(:payment_processing_failed)
        return redirect_to order_failed_route(step: "payment")
      end

      assign_order_id_from_params(payment)
      if payment.response_code.blank?
        flash[:notice] = I18n.t("payment_pending_przelewy24")
        return redirect_to order_failed_route(step: "summary")
      end

      process_payment_completion!
    end

    def status
      payload = parse_payload
      return head :bad_request if payload.nil?

      payment = Spree::Payment.find_by(identifier: payload["sessionId"].to_s)
      return head :not_found if payment.nil?

      gateway = payment.payment_method
      return head :unprocessable_entity unless gateway.is_a?(Spree::Gateway::Przelewy24)
      return head :unprocessable_entity unless valid_notification_signature?(gateway, payload)

      verified = verify_transaction(gateway, payment, payload)
      return head :unprocessable_entity unless verified

      payment.update_columns(response_code: payload["orderId"].to_s) if payload["orderId"].present?
      payment.pend! if payment.checkout? || payment.processing?

      head :ok
    end

    private

    def load_return_order
      @order = Spree::Order.find_by(number: params[:order_number]) || current_order
      return if @order&.token.present? && token_matches?

      flash[:error] = I18n.t("checkout.order_not_loaded")
      redirect_to main_app.shop_path
    end

    def token_matches?
      return false if params[:order_token].blank?

      token = params[:order_token].to_s
      return false if token.length != @order.token.length

      ActiveSupport::SecurityUtils.secure_compare(@order.token, token)
    end

    def assign_order_id_from_params(payment)
      order_id = params[:orderId] || params[:p24_order_id]
      return if order_id.blank? || payment.response_code.present?

      payment.update_columns(response_code: order_id.to_s)
    end

    def parse_payload
      body = request.body.read.to_s
      return if body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def valid_notification_signature?(gateway, payload)
      return false unless payload["merchantId"].to_i == gateway.preferred_merchant_id
      return false unless payload["posId"].to_i == (gateway.preferred_pos_id || gateway.preferred_merchant_id)

      expected = Przelewy24::Signature.notification(
        merchant_id: payload["merchantId"].to_i,
        pos_id: payload["posId"].to_i,
        session_id: payload["sessionId"].to_s,
        amount: payload["amount"].to_i,
        origin_amount: (payload["originAmount"] || payload["amount"]).to_i,
        currency: payload["currency"].to_s,
        order_id: payload["orderId"].to_i,
        method_id: payload["methodId"].to_i,
        statement: payload["statement"].to_s,
        crc: gateway.preferred_crc_key.to_s
      )

      signature = payload["sign"].to_s
      return false if signature.empty? || expected.length != signature.length

      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end

    def verify_transaction(gateway, payment, payload)
      verify_payload = {
        merchantId: gateway.preferred_merchant_id,
        posId: gateway.preferred_pos_id || gateway.preferred_merchant_id,
        sessionId: payment.identifier.to_s,
        amount: payload["amount"].to_i,
        currency: payload["currency"].to_s,
        orderId: payload["orderId"].to_i,
        sign: Przelewy24::Signature.verify(
          session_id: payment.identifier.to_s,
          order_id: payload["orderId"].to_i,
          amount: payload["amount"].to_i,
          currency: payload["currency"].to_s,
          crc: gateway.preferred_crc_key.to_s
        )
      }

      response = gateway.client.verify(verify_payload)
      response[:status] == 200 && response.dig(:body, "responseCode").to_i.zero?
    end
  end
end
