# frozen_string_literal: true

module ::Rollmaster
  class RollHistory
    SELECTOR_QUERY = ".bb-rollmaster[data-roll-id]".freeze

    def self.current_roll_ids(cooked)
      roll_entries(cooked).map { |entry| entry[:id] }
    end

    def self.current_rolls(post)
      current_ids = current_roll_ids(cooked_for_matching(post))
      return [] if current_ids.empty?

      ::Rollmaster::Roll.where(id: current_ids).to_a
    end

    def self.cooked_for_matching(post)
      return post.cooked if !post.id? || !post.persisted?

      previous_cooked = post.attribute_before_last_save("cooked")
      return previous_cooked if previous_cooked.present?

      post.class.unscoped.where(id: post.id).pick(:cooked)
    end

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
        .flat_map do |element|
          roll_ids = split_roll_ids(element["data-roll-id"])
          notations = split_roll_notations(element["data-notation"])
          desc = element["data-desc"].presence

          roll_ids.map.with_index do |roll_id, index|
            { id: roll_id, notation: notations[index] || notations.last.to_s, desc: desc }
          end
        end
    end

    def self.split_roll_ids(value)
      value.to_s.split(",").map(&:strip).reject(&:blank?).map(&:to_i)
    end

    def self.split_roll_notations(value)
      value.to_s.split("\n").map(&:strip).reject(&:blank?)
    end
  end
end
