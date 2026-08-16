# frozen_string_literal: true

module ::Rollmaster
  SELECTOR_QUERY = ".bb-rollmaster[data-notation]"

  class HandleCookedPostProcess
    def self.process(doc, post)
      # Add your processing logic here

      roll_elements =
        doc
          .css(SELECTOR_QUERY)
          .filter_map do |roll_element|
            notation = roll_element.attribute("data-notation").value
            next if notation.blank?

            roll_element.content = ""
            { raw: notation, dom: roll_element, desc: roll_element.attribute("data-desc")&.value }
          end

      return if roll_elements.empty?

      roll_elements.each { |element| element.merge!(process_roll(element[:raw], post)) }

      match_rolls(roll_elements, post) if post.id?
      save_rolls(roll_elements, post)

      roll_elements.each do |roll|
        roll[:dom].content = roll[:error] ? roll[:raw] : "#{roll[:raw]}: #{roll[:result]}"
        roll[:dom]["data-roll-id"] = roll[:id] if roll[:id]
      end

      true
    end

    def self.process_roll(notation, post)
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
      existing_rolls = Rollmaster::Roll.where(post_id: post.id).order(:created_at, :id).to_a
      return if existing_rolls.empty?

      rolls
        .reject { |r| r[:error] }
        .each do |roll|
          existing_roll = existing_rolls.find { |existing| existing.notation == roll[:formatted] }
          next if existing_roll.nil?

          roll[:id] = existing_roll.id
          roll[:result] = existing_roll.result
          existing_rolls.delete(existing_roll)
        end
    end

    def self.save_rolls(rolls, post)
      post.custom_fields[::Rollmaster::POST_CUSTOM_FIELD] = true
      post.save_custom_fields
      rolls
        .reject { |r| r[:error] }
        .each do |roll|
          if roll[:id]
            existing_roll = Rollmaster::Roll.find(roll[:id])
            if existing_roll.raw != roll[:raw] || existing_roll.notation != roll[:formatted] ||
                 existing_roll.desc != roll[:desc]
              existing_roll.update!(raw: roll[:raw], notation: roll[:formatted], desc: roll[:desc])
            end
          else
            new_roll =
              Rollmaster::Roll.create!(
                post_id: post.id,
                raw: roll[:raw],
                notation: roll[:formatted],
                result: roll[:result],
                desc: roll[:desc],
              )
            roll[:id] = new_roll.id
          end
        end
    end
  end
end
