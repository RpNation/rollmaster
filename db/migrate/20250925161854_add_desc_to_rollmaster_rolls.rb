# frozen_string_literal: true

class AddDescToRollmasterRolls < ActiveRecord::Migration[7.2]
  def change
    add_column :rollmaster_rolls, :desc, :string
  end
end
