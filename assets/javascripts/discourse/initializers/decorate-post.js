import { withPluginApi } from "discourse/lib/plugin-api";
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
