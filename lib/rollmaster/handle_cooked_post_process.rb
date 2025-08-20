# frozen_string_literal: true

module ::Rollmaster
  SELECTOR_QUERY = ".bb-rollmaster[data-notation]"

  class HandleCookedPostProcess
    def self.process(doc, post)
      # Add your processing logic here

      # { raw, dom }[]
      roll_elements = []

      # parse the post content for rolls and flatten
      doc
        .css(SELECTOR_QUERY)
        .each do |roll_element|
          original_notation = roll_element.attribute("data-notation").value

          next if original_notation.blank?

          original_notation
            .split(/\n/)
            .each do |notation|
              if notation.strip.empty?
                roll_elements << { raw: "", dom: roll_element } # let us keep empty lines
              else
                roll_elements << { raw: notation, dom: roll_element }
              end
            end
          roll_element.content = "" # clear the original notation
        end

      return if roll_elements.empty?

      # { raw, dom, formatted, result, error }[]
      roll_elements.each do |element|
        notation = element[:raw]
        next if notation.blank?

        element.merge!(process_roll(notation))
      end

      # { raw, dom, formatted, result, error, id }[]
      match_rolls(roll_elements, post) if post.id?
      save_rolls(roll_elements, post)

      p roll_elements
      roll_elements
        .group_by { |e| e[:dom] }
        .each do |dom, rolls|
          p "\n\n HELLO WORLD \n\n"
          p dom
          content =
            rolls.map do |e|
              if e[:error]
                e[:raw]
              elsif e[:raw].empty?
                ""
              else
                e[:raw] + ": " + e[:result] # TODO: consider decorating with spans
              end
            end
          p content
          dom.content = CGI.unescapeHTML(content.join("\n"))
          dom["data-roll-id"] = rolls.map { |e| e[:id] }.join(",") if rolls.any? { |e| e[:id] }
        end

      true
    end

    def self.process_roll(notation)
      begin
        formatted = Rollmaster::DiceEngine.format_notation(notation).first
        final = Rollmaster::DiceEngine.roll(notation).first
        { error: false, formatted: formatted, result: final }
      rescue Rollmaster::DiceEngine::RollError => e
        Rails.logger.warn("Rollmaster: Error formatting notation for post #{post.id}: #{e.message}")
        { error: true, formatted: nil, result: e.message }
      end
    end

    def self.match_rolls(rolls, post)
      existing_rolls = Rollmaster::Roll.where(post_id: post.id).to_a
      return if existing_rolls.empty?

      rolls
        .reject { |r| r[:raw].empty? || r[:error] }
        .each do |roll|
          existing_roll_idx =
            existing_rolls.index { |r| r.raw == roll[:raw] || r.notation == roll[:formatted] }
          next if existing_roll_idx.nil?

          existing_roll = existing_rolls[existing_roll_idx]
          roll[:id] = existing_roll.id
          roll[:result] = existing_roll.result # use existing roll result
          existing_rolls.delete_at(existing_roll_idx)
        end
    end

    def self.save_rolls(rolls, post)
      rolls
        .reject { |r| r[:raw].empty? || r[:error] }
        .each do |roll|
          if roll[:id]
            existing_roll = Rollmaster::Roll.find(roll[:id])
            existing_roll.update!(raw: roll[:raw], notation: roll[:formatted])
          else
            new_roll =
              Rollmaster::Roll.create!(
                post_id: post.id,
                raw: roll[:raw],
                notation: roll[:formatted],
                result: roll[:result],
              )
            roll[:id] = new_roll.id
          end
        end
    end
  end
end
