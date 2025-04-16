# frozen_string_literal: true

# name: rollmaster
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: RpNation
# url: TODO
# required_version: 3.0.0

enabled_site_setting :rollmaster_enabled

module ::Rollmaster
  PLUGIN_NAME = "discourse-rollmaster"
end

require_relative "lib/rollmaster/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
