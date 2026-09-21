import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "rollmaster-composer-toolbar",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.rollmaster_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addComposerToolbarPopupMenuOption({
        icon: "rollmaster-dices",
        label: "rollmaster.composer.insert_roll",
        action: (toolbarEvent) => {
          // `commands` is only present while the rich editor is active
          if (toolbarEvent.commands) {
            toolbarEvent.commands.insertRoll();
          } else {
            toolbarEvent.applySurround(
              "[roll]",
              "[/roll]",
              "rollmaster_notation",
              {
                multiline: false,
                useBlockMode: true,
              }
            );
          }
        },
      });
    });
  },
};
