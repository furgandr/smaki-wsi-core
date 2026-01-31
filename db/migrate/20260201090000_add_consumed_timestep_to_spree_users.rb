# frozen_string_literal: true

class AddConsumedTimestepToSpreeUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_users, :consumed_timestep, :integer
  end
end
