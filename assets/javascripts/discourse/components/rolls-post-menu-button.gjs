import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import RollHistoryEntry from "./roll-history-entry";

export default class RollsPostMenuButton extends Component {
  static hidden() {
    return false;
  }

  @tracked modalIsOpen = false;

  get currentRollIds() {
    return new Set(
      (this.args.post.current_roll_ids || []).map((rollId) => Number(rollId))
    );
  }

  get rolls() {
    return [...(this.args.post.rolls || [])]
      .sort(
        (left, right) => new Date(left.created_at) - new Date(right.created_at)
      )
      .map((roll) => ({
        ...roll,
        isCurrent: this.currentRollIds.has(Number(roll.id)),
      }));
  }

  @action
  showRolls() {
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
        class="rollmaster-roll-history-modal"
        data-test-roll-history-modal
        @title={{i18n "rollmaster.post.title"}}
        @closeModal={{fn (mut this.modalIsOpen) false}}
      >
        <div class="rollmaster-roll-history" data-test-roll-history>
          {{#each this.rolls as |roll|}}
            <RollHistoryEntry @roll={{roll}} />
          {{else}}
            <p
              class="rollmaster-roll-history__empty"
              data-test-roll-history-empty
            >
              {{i18n "rollmaster.post.empty"}}
            </p>
          {{/each}}
        </div>
      </DModal>
    {{/if}}
  </template>
}
