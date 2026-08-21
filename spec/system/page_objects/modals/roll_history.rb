# frozen_string_literal: true

module PageObjects
  module Modals
    class RollHistory < PageObjects::Modals::Base
      MODAL_SELECTOR = ".rollmaster-roll-history-modal"

      def row_count
        rows.size
      end

      def has_entry?(notation:, status:)
        entry_count(notation: notation, status: status).positive?
      end

      def entry_count(notation:, status:)
        body
          .all("[data-test-roll-history-row][data-test-roll-history-status='#{status.downcase}']")
          .count { |row| row.text.include?(notation) }
      end

      private

      def rows
        body.all("[data-test-roll-history-row]")
      end
    end
  end
end
