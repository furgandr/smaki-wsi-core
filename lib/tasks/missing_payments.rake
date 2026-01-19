# frozen_string_literal: true

# Find gaps in the sequence of payment ids.
# If there are gaps then see if there is a log entry with a payment result for
# the now lost payment. If there are some then you probably want to follow up
# with the affected enterprise and see if customers need to be refunded.
#
# ## Usage

# Report of the last 35 days:
#   rake ofn:missing_payments[35]
namespace :ofn do
  desc 'Find payments that got lost'
  task :missing_payments, [:days] => :environment do |_task_, args|
    days = args[:days]&.to_i || 7
    payments_sequence = Spree::Payment.where("created_at > ?", days.days.ago).order(:id).pluck(:id)
    missing_payment_ids = payments_range(payments_sequence) - payments_sequence
    puts "Gaps in the payments sequence: #{missing_payment_ids.count}"
    log_entries = Spree::LogEntry.where(
      source_type: "Spree::Payment",
      source_id: missing_payment_ids
    )
    print_csv(log_entries) if log_entries.present?
  end

  def payments_range(payments_sequence)
    if payments_sequence.empty?
      []
    else
      (payments_sequence.first..payments_sequence.last).to_a
    end
  end

  def print_csv(log_entries)
    CSV do |out|
      out << headers
      log_entries.each do |entry|
        add_row(entry, out)
      end
    end
  end

  def add_row(entry, out)
    details = safe_load_details(entry.details)
    out << row(details, extract_params(details))
  rescue StandardError
    Logger.new($stderr).warn(entry)
  end

  def safe_load_details(details)
    return {} if details.blank?

    permitted = [
      Date, DateTime, Time, ActiveSupport::TimeWithZone
    ]
    active_merchant_classes = [
      "ActiveMerchant::Billing::Response",
      "ActiveMerchant::Billing::AVSResult",
      "ActiveMerchant::Billing::CvvResult",
      "ActiveMerchant::Billing::MultiResponse"
    ]
    active_merchant_classes.each do |class_name|
      klass = class_name.safe_constantize
      permitted << klass if klass
    end

    Psych.safe_load(details, permitted_classes: permitted, permitted_symbols: [], aliases: false)
  rescue Psych::Exception => e
    Logger.new($stderr).warn("Skipped log details: #{e.class} #{e.message}")
    {}
  end

  def extract_params(details)
    return details.params if details.respond_to?(:params)
    return details["params"] if details.is_a?(Hash)

    {}
  end

  def headers
    [
      "Created", "Order", "Success", "Message", "Payment ID", "Action",
      "Amount", "Currencty", "Receipt"
    ]
  end

  def row(details, params)
    [
      Time.zone.at(params["created"] || 0).to_datetime,
      params["description"],
      extract_success(details),
      extract_message(details),
      params["id"],
      params["object"],
      params["amount"], params["currency"], params["receipt_url"]
    ]
  end

  def extract_success(details)
    return details.success? if details.respond_to?(:success?)
    return details["success"] if details.is_a?(Hash)

    nil
  end

  def extract_message(details)
    return details.message if details.respond_to?(:message)
    return details["message"] if details.is_a?(Hash)

    nil
  end
end
