# frozen_string_literal: true

require "yaml"

class SeedPolishStates < ActiveRecord::Migration[7.1]
  class Country < ActiveRecord::Base
    self.table_name = "spree_countries"
  end

  class State < ActiveRecord::Base
    self.table_name = "spree_states"
  end

  def up
    country = Country.find_by(iso: "PL")
    return unless country

    states_file = Rails.root.join("db", "default", "spree", "states_pl.yml")
    return unless File.exist?(states_file)

    states = YAML.load_file(states_file)

    ActiveRecord::Base.transaction do
      State.where(country_id: country.id).delete_all
      states.each do |state|
        State.create!(
          name: state["name"],
          abbr: state["abbr"],
          country_id: country.id
        )
      end
    end
  end

  def down
    country = Country.find_by(iso: "PL")
    return unless country

    State.where(country_id: country.id).delete_all
  end
end
