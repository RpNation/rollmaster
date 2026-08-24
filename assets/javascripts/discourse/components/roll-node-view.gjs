import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { cancel } from "@ember/runloop";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import discourseDebounce from "discourse/lib/debounce";
import dIcon from "discourse/ui-kit/helpers/d-icon";

const VALIDATION_DELAY = 150;

export default class RollNodeView extends Component {
  @service rollmasterDiceEngine;

  @tracked validationError = null;

  watchNotation = modifier((element, [notation]) => {
    this.#scheduleValidation(notation);
  });

  #contentDOM;
  #pending;

  constructor() {
    super(...arguments);

    // contentDOM (roll_desc + roll_notation) is appended into @dom by GlimmerNodeView before
    // this component renders, so it's always @dom's first child at this point.
    this.#contentDOM = this.args.dom.firstElementChild;
    this.args.dom.classList.add("composer-roll-node");
    this.#contentDOM?.classList.add("composer-roll-node__title");

    this.args.onSetup?.(this);
  }

  get notation() {
    let text = "";
    this.args.node.forEach((child) => {
      if (child.type.name === "roll_notation") {
        text = child.textContent;
      }
    });
    return text;
  }

  selectNode() {
    this.args.dom.classList.add("ProseMirror-selectednode");
  }

  deselectNode() {
    this.args.dom.classList.remove("ProseMirror-selectednode");
  }

  destroy() {
    cancel(this.#pending);
  }

  #scheduleValidation(notation) {
    if (!notation) {
      this.validationError = null;
      return;
    }

    this.#pending = discourseDebounce(
      this,
      this.#validate,
      notation,
      VALIDATION_DELAY
    );
  }

  async #validate(notation) {
    const error = await this.rollmasterDiceEngine.validate(notation);

    if (this.isDestroying || this.isDestroyed) {
      return;
    }

    this.validationError = error;
  }

  <template>
    {{dIcon "rollmaster-dices" class="composer-roll-node__icon"}}
    <span hidden {{this.watchNotation this.notation}}></span>
    {{#if this.validationError}}
      <p
        class="composer-roll-node__error"
        contenteditable="false"
      >{{this.validationError}}</p>
    {{/if}}
  </template>
}
