# frozen_string_literal: true

module ::Rollmaster
  class Roll < ActiveRecord::Base
    self.table_name = "rollmaster_rolls"

    # let Post to Roll association occur via the cooked text.
    # Roll to Post association will be explicit for backtracking (i.e. auditing).
    belongs_to :post
    validates :raw, presence: true
    validates :notation, presence: true
    validates :result, presence: true
  end
end
