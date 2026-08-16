import { withPluginApi } from "discourse/lib/plugin-api";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import RollsPostMenuButton from "../components/rolls-post-menu-button";

const RollResult = <template>
  <blockquote
    class="bb-rollmaster-result"
    dir="auto"
    data-roll-id={{@roll.id}}
    data-desc={{@roll.desc}}
    data-notation={{@roll.notation}}
    data-result={{@roll.result}}
  >
    <p class="bb-rollmaster-title">
      <span class="bb-rollmaster-description">
        {{dIcon "rollmaster-dices"}}
        {{@roll.desc}}:
      </span>
      <span class="bb-rollmaster-notation">{{@roll.notation}}</span>
    </p>
    <p class="bb-rollmaster-results">{{@roll.result}}</p>
  </blockquote>
</template>;

function decorateCookedElement(el, helper) {
  if (!helper?.getModel()?.has_rolls) {
    return;
  }

  const rolls = helper.getModel().rolls;
  const rollElems = el.querySelectorAll(
    ".bb-rollmaster[data-notation][data-roll-id]"
  );

  rollElems.forEach((rollElem) => {
    const rollId = rollElem.getAttribute("data-roll-id");
    const roll = rolls.find((r) => r.id.toString() === rollId);
    if (!roll) {
      return;
    }

    roll.desc ??= i18n("rollmaster.bbcode.default");

    // full replacement of the roll element with a glimmer component
    const wrapper = document.createElement("div");
    wrapper.classList.add("bb-rollmaster-wrapper");
    helper.renderGlimmer(
      wrapper,
      <template><RollResult @roll={{roll}} /></template>
    );
    rollElem.replaceWith(wrapper);
  });
}

export default {
  name: "rollmaster-decorate-post",
  initialize() {
    withPluginApi((api) => {
      api.decorateCookedElement(decorateCookedElement);

      api.registerValueTransformer(
        "post-menu-buttons",
        ({ value: dag, context: { post } }) => {
          if (!post.has_rolls) {
            return;
          }
          dag.add("rollmaster-view-rolls", RollsPostMenuButton, {
            before: ["delete", "showMore"],
            after: ["bookmark", "edit"],
          });
        }
      );
    });
  },
};
