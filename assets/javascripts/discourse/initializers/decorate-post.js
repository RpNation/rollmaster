import icon from "discourse/helpers/d-icon";
import { withPluginApi } from "discourse/lib/plugin-api";
import { sanitize } from "discourse/lib/text";
import { applyValueTransformer } from "discourse/lib/transformer";
import RollsPostMenuButton from "../components/rolls-post-menu-button";

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

    let htmlString = `<blockquote
  dir="auto"
  class="bb-rollmaster-result"
  data-roll-id="${roll.id}"
  data-desc="${sanitize(roll.desc || "")}"
  data-notation="${sanitize(roll.notation)}"
  data-result="${sanitize(roll.result)}"
>
  <p class="bb-rollmaster-title">
    <span class="bb-rollmaster-description">
      ${icon("rollmaster-dices")}
      ${sanitize(roll.desc || "Roll")}:
    </span>
    <span class="bb-rollmaster-notation">${sanitize(roll.notation)}</span>
  </p>
  <p class="bb-rollmaster-results">${roll.result}</p>
</blockquote>`;

    htmlString = applyValueTransformer(
      "rollmaster-cooked-roll-result",
      htmlString,
      { roll, post: helper.getModel(), helper, element: rollElem }
    );
    rollElem.outerHTML = htmlString;
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
