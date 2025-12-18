# frozen_string_literal: true

require "yaml"

class SeedPolishStates < ActiveRecord::Migration[7.1]
  def up
    country = Spree::Country.find_by(iso: "PL")
    return unless country

    states_file = Rails.root.join("db", "default", "spree", "states_pl.yml")
    return unless File.exist?(states_file)

    states = YAML.load_file(states_file)

    ActiveRecord::Base.transaction do
      Spree::State.where(country: country).delete_all
      states.each do |state|
        Spree::State.create!(
          name: state["name"],
          abbr: state["abbr"],
          country: country
        )
      end
    end
  end

  def down
    country = Spree::Country.find_by(iso: "PL")
    return unless country

    Spree::State.where(country: country).delete_all
  end
end
