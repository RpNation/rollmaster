import { withPluginApi } from "discourse/lib/plugin-api";
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
  console.log(rollElems, rolls);

  rollElems.forEach((rollElem) => {
    const rollId = rollElem.getAttribute("data-roll-id");
    const roll = rolls.find((r) => r.id.toString() === rollId);
    if (!roll) {
      return;
    }
    // todo: add blockquote around roll result
    let htmlString = `<blockquote
   dir="auto"
   class=".bb-rollmaster-result"
   data-roll-id="${roll.id}"
   data-notation="${roll.notation}"
   data-result="${roll.result}"
 >${roll.result}</blockquote>`;

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
      api.addValueTransformerName("rollmaster-cooked-roll-result");
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
