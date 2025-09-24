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

# == Schema Information
#
# Table name: rollmaster_rolls
#
#  id         :bigint           not null, primary key
#  post_id    :integer
#  raw        :string
#  notation   :string
#  result     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#  index_rollmaster_rolls_on_post_id  (post_id)
