import discourseDebounce from "discourse/lib/debounce";
import { iconElement } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import RollsPostMenuButton from "../components/rolls-post-menu-button";

const SAVED_SELECTOR = "blockquote.bb-rollmaster-result[data-roll-id]";
const PENDING_SELECTOR = "blockquote.bb-rollmaster-result:not([data-roll-id])";
const VALIDATION_DELAY = 150;

function applyResult(blockquote, resultsEl, error) {
  if (error) {
    resultsEl.textContent = error;
    blockquote.classList.add("--error");
  } else {
    resultsEl.textContent = "???";
    blockquote.classList.remove("--error");
  }
}

function validatePendingElems(diceEngine, pendingElems) {
  pendingElems.forEach((blockquote) => {
    const notation = blockquote.getAttribute("data-notation");
    const resultsEl = blockquote.querySelector(".bb-rollmaster-results");
    if (!notation || !resultsEl) {
      return;
    }

    diceEngine
      .validate(notation)
      .then((error) => applyResult(blockquote, resultsEl, error));
  });
}

function decorateCookedElement(diceEngine, el, helper) {
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

  let hasUncached = false;

  pendingElems.forEach((blockquote) => {
    const descEl = blockquote.querySelector(".bb-rollmaster-description");
    if (descEl && !descEl.querySelector(".d-icon")) {
      descEl.prepend(iconElement("rollmaster-dices"));
    }

    // Every re-cook rebuilds this element from scratch. Fast track any cached validation
    const notation = blockquote.getAttribute("data-notation");
    const resultsEl = blockquote.querySelector(".bb-rollmaster-results");
    if (notation && resultsEl) {
      const cached = diceEngine.getCachedValidation(notation);
      if (cached !== undefined) {
        applyResult(blockquote, resultsEl, cached);
      } else {
        hasUncached = true;
      }
    }
  });

  if (!hasUncached) {
    return;
  }

  discourseDebounce(
    decorateCookedElement,
    validatePendingElems,
    diceEngine,
    pendingElems,
    VALIDATION_DELAY
  );
}

export default {
  name: "rollmaster-decorate-post",
  initialize(container) {
    const diceEngine = container.lookup("service:rollmaster-dice-engine");

    withPluginApi((api) => {
      api.decorateCookedElement((el, helper) =>
        decorateCookedElement(diceEngine, el, helper)
      );

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
