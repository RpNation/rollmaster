# frozen_string_literal: true

class CreateRollmasterRolls < ActiveRecord::Migration[7.2]
  def change
    create_table :rollmaster_rolls do |t|
      t.integer :post_id
      t.string :raw
      t.string :notation
      t.string :result

      t.timestamps
    end
    add_index :rollmaster_rolls, :post_id
  end
end
