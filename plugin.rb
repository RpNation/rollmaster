# frozen_string_literal: true

# name: rollmaster
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: RpNation
# url: TODO
# required_version: 3.0.0

enabled_site_setting :rollmaster_enabled

register_asset "stylesheets/common/index.scss"

module ::Rollmaster
  PLUGIN_NAME = "rollmaster".freeze
  POST_CUSTOM_FIELD = "rollmaster_processed".freeze
end

require_relative "lib/rollmaster/engine"
require_relative "lib/rollmaster/roll_history"

after_initialize do
  # Code which should run after Rails has finished booting

  register_svg_icon "rollmaster-dices"

  # I don't think this is needed, but it doesn't hurt to be safe
  ::Rollmaster::DiceEngine.reset_context

  register_post_custom_field_type(::Rollmaster::POST_CUSTOM_FIELD, :boolean)

  on(:before_post_process_cooked) do |doc, post|
    ::Rollmaster::HandleCookedPostProcess.process(doc, post) if SiteSetting.rollmaster_enabled
  end

  add_to_class(:post, :has_rolls?) { custom_fields[::Rollmaster::POST_CUSTOM_FIELD] || false }
  add_to_class(:post, :rolls) do
    ::Rollmaster::Roll.where(post_id: id).order(created_at: :desc, id: :desc) if has_rolls?
  end

  add_to_serializer(:post, :has_rolls?) { object.has_rolls? }
  add_to_serializer(:post, :rolls, include_condition: -> { object.has_rolls? }) do
    (object.rolls || []).map { |roll| ::Rollmaster::RollSerializer.new(roll, root: false) }
  end

  add_to_serializer(
    :post_revision,
    :roll_changes,
    include_condition: -> { roll_changes.present? },
  ) { ::Rollmaster::RollHistory.roll_changes(previous["cooked"], current["cooked"]) }

  # TODO: consider :chat_message_processed as well
end
