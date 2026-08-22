# frozen_string_literal: true

module ::Rollmaster
  SELECTOR_QUERY = "blockquote.bb-rollmaster-result[data-notation]:not([data-roll-id])"

  class HandleCookedPostProcess
    def self.process(doc, post)
      roll_elements =
        doc
          .css(SELECTOR_QUERY)
          .filter_map do |roll_element|
            notation = roll_element.attribute("data-notation")&.value
            next if notation.blank?

            { raw: notation, dom: roll_element, desc: roll_element.attribute("data-desc")&.value }
          end

      return if roll_elements.empty?

      format_rolls(roll_elements, post)
      match_rolls(roll_elements, post) if post.id?
      roll_unmatched(roll_elements, post)
      save_rolls(roll_elements, post)

      roll_elements.each do |roll|
        result_el = roll[:dom].at_css(".bb-rollmaster-results")
        desc_el = roll[:dom].at_css(".bb-rollmaster-description")

        svg = SvgSprite.raw_svg("rollmaster-dices")
        desc_el.prepend_child(Nokogiri::HTML5.fragment(svg)) if desc_el && svg.present?

        if roll[:error]
          roll[:dom]["class"] = "#{roll[:dom]["class"]} --error"
          result_el&.content = roll[:result]
        else
          roll[:dom]["data-roll-id"] = roll[:id].to_s if roll[:id]
          result_el&.content = roll[:result]
        end
      end

      true
    end

    def self.format_rolls(rolls, post)
      apply_batch(
        rolls,
        rolls.map { |roll| roll[:raw] },
        :format_notation,
        "formatting",
        post,
      ) { |roll, value| roll[:formatted] = value }
    end

    # Only rolls elements that survived formatting and weren't matched to an existing roll
    def self.roll_unmatched(rolls, post)
      unmatched = rolls.reject { |roll| roll[:error] || roll[:id] }
      return if unmatched.empty?

      apply_batch(
        unmatched,
        unmatched.map { |roll| roll[:raw] },
        :roll,
        "rolling",
        post,
      ) { |roll, value| roll[:result] = value }
    end

    # Calls a DiceEngine method as a batch, and applies the results to the rolls.
    def self.apply_batch(rolls, notations, method, action, post)
      results =
        begin
          Rollmaster::DiceEngine.public_send(method, *notations)
        rescue MiniRacer::Error => e
          Discourse.warn_exception(
            e,
            message:
              "Rollmaster: Dice engine failure while #{action} notations for post #{post.id}",
          )
          # The engine may be left in a bad state (e.g. after hitting the memory limit), so make
          # sure the next roll gets a fresh context instead of continuing to fail.
          Rollmaster::DiceEngine.reset_context
          nil
        end

      rolls.each_with_index do |roll, index|
        result = results && results[index]

        if result.nil?
          roll[:error] = true
          roll[:result] = I18n.t("rollmaster.engine_error")
        elsif result["ok"]
          yield roll, result["value"]
        else
          Rails.logger.warn(
            "Rollmaster: Invalid notation while #{action} for post #{post.id}: #{result["msg"]}",
          )
          roll[:error] = true
          roll[:result] = result["msg"]
        end
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
      successful_rolls = rolls.reject { |r| r[:error] }

      successful_rolls.each do |roll|
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

      return if successful_rolls.empty?

      post.custom_fields[::Rollmaster::POST_CUSTOM_FIELD] = true
      post.save_custom_fields
    end
  end
end
