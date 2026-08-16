import { iconElement } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import { applyValueTransformer } from "discourse/lib/transformer";
import RollsPostMenuButton from "../components/rolls-post-menu-button";

function rollResultElement(roll) {
  const result = document.createElement("blockquote");
  result.dir = "auto";
  result.className = "bb-rollmaster-result";
  result.dataset.rollId = roll.id;
  result.dataset.desc = roll.desc || "";
  result.dataset.notation = roll.notation;
  result.dataset.result = roll.result;

  const title = document.createElement("p");
  title.className = "bb-rollmaster-title";

  const description = document.createElement("span");
  description.className = "bb-rollmaster-description";
  description.append(iconElement("rollmaster-dices"));
  description.append(` ${roll.desc || "Roll"}:`);
  title.append(description);

  const notation = document.createElement("span");
  notation.className = "bb-rollmaster-notation";
  notation.textContent = roll.notation;
  title.append(notation);
  result.append(title);

  const rollResult = document.createElement("p");
  rollResult.className = "bb-rollmaster-results";
  rollResult.textContent = roll.result;
  result.append(rollResult);

  return result;
}

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

    const htmlString = applyValueTransformer(
      "rollmaster-cooked-roll-result",
      rollResultElement(roll).outerHTML,
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
