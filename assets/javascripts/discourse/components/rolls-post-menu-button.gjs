import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import DModal from "discourse/components/d-modal";
import { fn } from "@ember/helper";

export default class RollsPostMenuButton extends Component {
  static hidden() {
    return false;
  }

  @tracked rolls = this.args.post.rolls || [];
  @tracked modalIsOpen = false;

  @action
  showRolls() {
    console.log("Rolls:", this.rolls);
    // Implement the logic to show rolls, e.g., open a modal or dropdown
    this.modalIsOpen = true;
  }

  <template>
    <DButton
      class="post-action-menu__view-rolls"
      ...attributes
      @action={{this.showRolls}}
      @icon="rollmaster-dices"
      @title="rollmaster.post.title"
    />

    {{#if this.modalIsOpen}}
      <DModal
        @title={{i18n "rollmaster.post.title"}}
        @closeModal={{fn (mut this.modalIsOpen) false}}
      >
        hello world
      </DModal>
    {{/if}}
  </template>
}
