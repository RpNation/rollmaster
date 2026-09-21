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

after_initialize do
  register_svg_icon "rollmaster-dices"

  # I don't think this is needed, but it doesn't hurt to be safe
  ::Rollmaster::DiceEngine.reset_context

  register_post_custom_field_type(::Rollmaster::POST_CUSTOM_FIELD, :boolean)
  topic_view_post_custom_fields_allowlister { [::Rollmaster::POST_CUSTOM_FIELD] }

  on(:before_post_process_cooked) do |doc, post|
    ::Rollmaster::HandleCookedPostProcess.process(doc, post) if SiteSetting.rollmaster_enabled
  end

  add_to_class(:post, :has_rolls?) { custom_fields[::Rollmaster::POST_CUSTOM_FIELD] || false }

  reloadable_patch do
    ::Post.has_many :rolls,
                    -> { order(created_at: :desc, id: :desc) },
                    class_name: "Rollmaster::Roll",
                    dependent: :delete_all
  end
  add_to_serializer(:post, :has_rolls?) { !!post_custom_fields[::Rollmaster::POST_CUSTOM_FIELD] }

  # TODO: consider :chat_message_processed as well
end
