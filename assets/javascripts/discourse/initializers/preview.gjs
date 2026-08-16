import { withPluginApi } from "discourse/lib/plugin-api";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import ComposerValidRoll from "../components/composer-valid-roll";

const RollPreview = <template>
  <blockquote
    class="bb-rollmaster-result bb-rollmaster-preview"
    dir="auto"
    data-notation={{@data.notation}}
  >
    <p class="bb-rollmaster-title">
      <span class="bb-rollmaster-description">
        {{dIcon "rollmaster-dices"}}
        {{@data.desc}}:
      </span>
      <span class="bb-rollmaster-notation">{{@data.notation}}</span>
    </p>
    <p class="bb-rollmaster-results">???</p>
  </blockquote>
</template>;

function initializeRollmasterPreview(api) {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.rollmaster_enabled) {
    return;
  }

  api.renderInOutlet("after-d-editor", ComposerValidRoll);

  api.decorateCookedElement((element, helper) => {
    if (helper.getModel()) {
      return;
    }
    // This is a preview, no model

    const rollElems = element.querySelectorAll(
      ".bb-rollmaster[data-notation]:not([data-roll-id])"
    );

    rollElems.forEach((rollElem) => {
      const notation = rollElem.dataset.notation;
      if (!notation) {
        return;
      }
      const desc = rollElem.dataset.desc || i18n("rollmaster.bbcode.default");

      // TODO: add notation validator here, and show error if invalid

      const wrapper = document.createElement("div");
      wrapper.classList.add("bb-rollmaster-wrapper");

      helper.renderGlimmer(wrapper, RollPreview, {
        notation,
        desc,
      });

      rollElem.replaceWith(wrapper);
    });
  });
}

export default {
  name: "rollmaster-composer-preview",
  initialize() {
    withPluginApi(initializeRollmasterPreview);
  },
};
