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
  PLUGIN_NAME = "rollmaster"
end

require_relative "lib/rollmaster/engine"

after_initialize do
  # Code which should run after Rails has finished booting

  register_svg_icon "rollmaster-dices"

  # I don't think this is needed, but it doesn't hurt to be safe
  ::Rollmaster::DiceEngine.reset_context

  on(:post_process_cooked) { |doc, post| ::Rollmaster::HandleCookedPostProcess.process(doc, post) }
  # TODO: consider :chat_message_processed as well
end
