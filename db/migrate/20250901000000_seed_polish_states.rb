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
      states.each do |state|
        record = State.find_or_initialize_by(
          country_id: country.id,
          abbr: state["abbr"]
        )
        record.name = state["name"]
        record.save!
      end
    end
  end

  def down
    # no-op to avoid deleting states referenced by addresses
  end
end
