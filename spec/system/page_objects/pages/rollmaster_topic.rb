# frozen_string_literal: true

module PageObjects
  module Pages
    class RollmasterTopic < PageObjects::Pages::Topic
      def has_roll_history_button?(post)
        within_post(post) { has_css?(".post-action-menu__view-rolls") }
      end

      def open_roll_history(post)
        within_post(post) { find(".post-action-menu__view-rolls").click }
      end
    end
  end
end
