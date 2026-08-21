# frozen_string_literal: true

module ::Rollmaster
  class RollHistory
    SELECTOR_QUERY = ".bb-rollmaster[data-roll-id]".freeze

    def self.roll_changes(previous_cooked, current_cooked)
      previous_rolls = roll_entries(previous_cooked)
      current_rolls = roll_entries(current_cooked)

      return if previous_rolls.blank? && current_rolls.blank?
      return if previous_rolls == current_rolls

      { previous: previous_rolls, current: current_rolls }
    end

    def self.roll_entries(cooked)
      roll_snapshots = parse_roll_snapshots(cooked)
      return [] if roll_snapshots.empty?

      results_by_id =
        ::Rollmaster::Roll
          .where(id: roll_snapshots.map { |entry| entry[:id] })
          .pluck(:id, :result)
          .to_h

      roll_snapshots.filter_map do |entry|
        result = results_by_id[entry[:id]]
        next if result.blank?

        entry.merge(result: result)
      end
    end

    def self.parse_roll_snapshots(cooked)
      return [] if cooked.blank?

      Nokogiri::HTML5
        .fragment(cooked)
        .css(SELECTOR_QUERY)
        .filter_map do |element|
          id = element["data-roll-id"].to_i
          next if id.zero?

          {
            id: id,
            notation: element["data-notation"].to_s.strip,
            desc: element["data-desc"].presence,
          }
        end
    end
  end
end
