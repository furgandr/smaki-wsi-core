# frozen_string_literal: true

class EnterpriseRatingMailer < ApplicationMailer
  include I18nHelper

  def seller_rating_received(rating_or_id)
    @rating = rating_or_id.is_a?(EnterpriseRating) ? rating_or_id : EnterpriseRating.find(rating_or_id)
    @order = @rating.order
    @enterprise = @rating.enterprise

    @buyer_name = @order&.bill_address&.full_name.presence || @order&.user&.email || @order&.email

    I18n.with_locale valid_locale(@enterprise&.owner) do
      subject = I18n.t(
        "enterprise_rating_mailer.seller_rating_received.subject",
        enterprise: @enterprise&.name,
        order: @order&.number
      )

      mail(
        to: @enterprise.contact.email,
        subject:,
        reply_to: @order&.email
      )
    end
  end
end
