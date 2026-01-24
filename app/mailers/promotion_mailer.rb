# frozen_string_literal: true

class PromotionMailer < ApplicationMailer
  include I18nHelper

  def expiring_soon(promotion)
    @promotion = promotion
    @supplier = promotion.supplier
    @distributor = promotion.distributor
    @ends_at = promotion.ends_at

    I18n.with_locale(owner_locale) do
      return if recipient_email.blank?

      mail(
        to: recipient_email,
        subject: subject
      )
    end
  end

  private

  def recipient_email
    @supplier.owner&.email || @supplier.contact&.email
  end

  def owner_locale
    valid_locale(@supplier.owner)
  end

  def subject
    I18n.t("promotion_mailer.expiring_soon.subject", site: Spree::Config.site_name)
  end
end
