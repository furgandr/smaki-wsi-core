# frozen_string_literal: true

unless Spree::Zone.find_by(name: "EU_VAT")
  eu_vat = Spree::Zone.new(
    name: "EU_VAT", description: "Countries that make up the EU VAT zone."
  )

  ["Poland", "Finland", "Portugal", "Romania", "Germany", "France",
   "Slovakia", "Hungary", "Slovenia", "Ireland", "Austria", "Spain",
   "Italy", "Belgium", "Sweden", "Latvia", "Bulgaria", "United Kingdom",
   "Lithuania", "Cyprus", "Luxembourg", "Malta", "Denmark", "Netherlands",
   "Estonia"].each do |name|
    country = Spree::Country.find_by(name:)
    next unless country

    eu_vat.zone_members.new(zoneable: country)
  end
  eu_vat.save! if eu_vat.zone_members.any?
end

unless Spree::Zone.find_by(name: "North America")
  north_america = Spree::Zone.new(name: "North America", description: "USA + Canada")

  ["United States", "Canada"].each do |name|
    country = Spree::Country.find_by(name:)
    next unless country

    north_america.zone_members.new(zoneable: country)
  end
  north_america.save! if north_america.zone_members.any?
end
