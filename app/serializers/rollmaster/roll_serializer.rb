# frozen_string_literal: true

module ::Rollmaster
  class RollSerializer < ApplicationSerializer
    attributes :id, :post_id, :raw, :notation, :result, :created_at, :updated_at
  end
end
