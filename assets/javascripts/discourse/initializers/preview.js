import { debounce } from "@ember/runloop";
import loadscript from "discourse/lib/load-script";
import { withPluginApi } from "discourse/lib/plugin-api";
/* global rpgDiceRoller */

const PARENT_PREVIEW_WRAPPER_CLASS = "d-editor-preview";
const ROLL_SELECTOR = ".bb-rollmaster[data-notation]";
const NOTE_ATTR = "data-notation";

function validateRoll(post) {
  /** @type NodeList */
  const rollEls = post.querySelectorAll(ROLL_SELECTOR);
  /** @type string[] */
  rollEls.forEach((el) => {
    /** @type string */
    const notation = el.getAttribute(NOTE_ATTR);
    const rolls = notation
      .split("\n")
      .map((r) => r.trim())
      .filter(Boolean);
    rolls.forEach((roll) => {
      try {
        rpgDiceRoller.Parser.parse(roll);
      } catch (err) {
        console.error(err, el);
        // TODO: add UI display on error
      }
    });
  });
}

/**
 * Check if the post is a preview.
 * @param {HTMLElement} post
 */
function checkIsPreview(post) {
  return post.classList.contains(PARENT_PREVIEW_WRAPPER_CLASS);
}

function initializeRollmasterPreview(api) {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.rollmaster_enabled) {
    return;
  }

  api.decorateCookedElement(
    (post) => {
      Promise.all([
        loadscript("/plugins/rollmaster/vendors/math.js"),
        loadscript("/plugins/rollmaster/vendors/random-js.min.js"),
      ])
        .then(() => {
          return loadscript(
            "/plugins/rollmaster/vendors/rpg-dice-roller.min.js"
          );
        })
        .then(() => {
          if (checkIsPreview(post) && post.querySelector(ROLL_SELECTOR)) {
            debounce(this, validateRoll, post, 1000);
          }
        });
    },
    {
      id: "decorate composer preview",
      afterAdopt: true,
    }
  );
}

export default {
  name: "rollmaster-composer-preview",
  initialize() {
    withPluginApi("2.0.0", initializeRollmasterPreview);
  },
};
