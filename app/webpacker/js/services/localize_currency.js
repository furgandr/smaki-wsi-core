// Convert number to string currency using injected currency configuration.

// Requires global variable from page: ofn_currency_config
export default function (amount) {
  // Set country code (eg. "US").
  const currency_code = ofn_currency_config.display_currency
    ? " " + ofn_currency_config.currency
    : "";
  // Always show 2 decimal places.
  const decimals = 2;
  // Set format if the currency symbol should come after the number, otherwise (default) use the locale setting.
  const format = ofn_currency_config.symbol_position === "after" ? "%n %u" : undefined;
  // We need to use parseFloat as the amount should come in as a string.
  amount = parseFloat(amount);

  // Build the final price string.
  return (
    I18n.toCurrency(amount, {
      precision: decimals,
      unit: ofn_currency_config.symbol,
      format: format,
      strip_insignificant_zeros: false,
    }) + currency_code
  );
}
