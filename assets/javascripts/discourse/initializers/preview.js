import { withPluginApi } from "discourse/lib/plugin-api";
import ComposerValidRoll from "../components/composer-valid-roll";

function initializeRollmasterPreview(api) {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.rollmaster_enabled) {
    return;
  }

  api.renderInOutlet("after-d-editor", ComposerValidRoll);
}

export default {
  name: "rollmaster-composer-preview",
  initialize() {
    withPluginApi("2.0.0", initializeRollmasterPreview);
  },
};
