import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { debounce } from "@ember/runloop";
import icon from "discourse/helpers/d-icon";
import loadscript from "discourse/lib/load-script";
import { cook } from "discourse/lib/text";
import { i18n } from "discourse-i18n";
/* global rpgDiceRoller */

const ROLL_SELECTOR = ".bb-rollmaster[data-notation]";
const NOTE_ATTR = "data-notation";

export default class ComposerValidRoll extends Component {
  @tracked hasRolls = false;
  @tracked loading = false;
  @tracked errors = [];

  get title() {
    if (this.loading) {
      return i18n("rollmaster.validator.loading");
    }
    if (!this.hasRolls) {
      return "";
    }
    if (this.errors.length) {
      return i18n("rollmaster.validator.error");
    } else {
      return i18n("rollmaster.validator.success");
    }
  }

  /**
   * @returns {string}
   */
  get raw() {
    return this.args.composer.reply;
  }

  get mayHaveRolls() {
    const str = this.raw.toLowerCase();
    return str.includes("[roll]") && str.includes("[/roll]");
  }

  @action
  async checkRolls(raw) {
    this.loading = true;
    const actualPreview = this.args.composer.getCookedHtml();
    if (actualPreview) {
      this.validateRollsFromPost(
        document.querySelector("#reply-control.show-preview .d-editor-preview")
      );
      return;
    }

    const cooked = await cook(raw);
    const template = document.createElement("template");
    template.innerHTML = cooked;
    this.validateRollsFromPost(template.content);
  }

  @action
  asyncCheckRolls() {
    debounce(this, this.checkRolls, this.raw, 1000);
  }

  /**
   * @param {Element} post
   */
  async validateRollsFromPost(post) {
    await this.loadRpgDiceRoller();
    /** @type NodeList */
    const rollEls = post.querySelectorAll(ROLL_SELECTOR);
    this.errors = [];
    this.hasRolls = !!rollEls.length;
    this.loading = false;

    if (!this.hasRolls) {
      return;
    }

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
          this.errors.push(err);
        }
      });
    });
  }

  async loadRpgDiceRoller() {
    await Promise.all([
      loadscript("/plugins/rollmaster/vendors/math.js"),
      loadscript("/plugins/rollmaster/vendors/random-js.min.js"),
    ]);
    await loadscript("/plugins/rollmaster/vendors/rpg-dice-roller.min.js");
  }

  <template>
    {{#if this.mayHaveRolls}}
      <div
        {{didInsert this.asyncCheckRolls}}
        {{didUpdate this.asyncCheckRolls this.raw}}
        class="rollmaster-valid-composer"
        title={{this.title}}
      >
        {{#if this.hasRolls}}
          {{icon "rollmaster-dices" class="svg-roll"}}
          {{#if this.errors.length}}
            {{icon "triangle-exclamation" class="roll__invalid"}}
          {{/if}}
        {{/if}}

        {{#if this.loading}}
          {{icon "spinner" class="rollmaster-spinner"}}
        {{/if}}
      </div>
    {{/if}}
  </template>
}
