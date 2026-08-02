# frozen_string_literal: true

module PageObjects
  module Modals
    class RollmasterPostHistory < PageObjects::Modals::PostHistory
      def previous_roll_entries
        roll_entries("[data-test-roll-revision-previous]")
      end

      def current_roll_entries
        roll_entries("[data-test-roll-revision-current]")
      end

      def has_previous_roll_entry?(notation)
        previous_roll_entries.any? { |entry| entry.include?(notation) }
      end

      def has_current_roll_entry?(notation)
        current_roll_entries.any? { |entry| entry.include?(notation) }
      end

      private

      def roll_entries(scope)
        body.all("#{scope} .rollmaster-revision-rolls__entry").map(&:text)
      end
    end
  end
end
