import { iconElement } from "discourse/lib/icon-library";
import loadscript from "discourse/lib/load-script";
import { withPluginApi } from "discourse/lib/plugin-api";
import RollsPostMenuButton from "../components/rolls-post-menu-button";

/* global rpgDiceRoller */

const SAVED_SELECTOR = "blockquote.bb-rollmaster-result[data-roll-id]";
const PENDING_SELECTOR = "blockquote.bb-rollmaster-result:not([data-roll-id])";

async function loadRpgDiceRoller() {
  await Promise.all([
    loadscript("/plugins/rollmaster/vendors/math.js"),
    loadscript("/plugins/rollmaster/vendors/random-js.min.js"),
  ]);
  await loadscript("/plugins/rollmaster/vendors/rpg-dice-roller.min.js");
}

function decorateCookedElement(el, helper) {
  const model = helper?.getModel();

  if (model?.has_rolls) {
    const savedElems = el.querySelectorAll(SAVED_SELECTOR);
    model.current_roll_ids = [...savedElems].map((e) =>
      Number(e.getAttribute("data-roll-id"))
    );
  }

  const pendingElems = el.querySelectorAll(PENDING_SELECTOR);
  if (!pendingElems.length) {
    return;
  }

  pendingElems.forEach((blockquote) => {
    const descEl = blockquote.querySelector(".bb-rollmaster-description");
    if (descEl && !descEl.querySelector(".d-icon")) {
      descEl.prepend(iconElement("rollmaster-dices"));
    }
  });

  loadRpgDiceRoller().then(() => {
    pendingElems.forEach((blockquote) => {
      const notation = blockquote.getAttribute("data-notation");
      const resultsEl = blockquote.querySelector(".bb-rollmaster-results");
      if (!notation || !resultsEl) {
        return;
      }

      try {
        rpgDiceRoller.Parser.parse(notation);
        resultsEl.textContent = "???";
        blockquote.classList.remove("--error");
      } catch (err) {
        resultsEl.textContent = err.message;
        blockquote.classList.add("--error");
      }
    });
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
