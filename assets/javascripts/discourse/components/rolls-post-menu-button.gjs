import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import RollHistoryEntry from "./roll-history-entry";

export default class RollsPostMenuButton extends Component {
  static hidden() {
    return false;
  }

  @tracked modalIsOpen = false;
  @tracked loading = false;
  @tracked rolls = [];

  get currentRollIds() {
    return new Set(
      (this.args.post.current_roll_ids || []).map((rollId) => Number(rollId))
    );
  }

  get sortedRolls() {
    return [...this.rolls]
      .sort(
        (left, right) => new Date(left.created_at) - new Date(right.created_at)
      )
      .map((roll) => ({
        ...roll,
        isCurrent: this.currentRollIds.has(Number(roll.id)),
      }));
  }

  @action
  async showRolls() {
    this.modalIsOpen = true;
    this.loading = true;

    try {
      const response = await ajax(
        `/rollmaster/rolls/${this.args.post.id}.json`
      );
      this.rolls = response.rolls;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
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
        <DConditionalLoadingSpinner @condition={{this.loading}}>
          <div class="rollmaster-roll-history" data-test-roll-history>
            {{#each this.sortedRolls as |roll|}}
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
        </DConditionalLoadingSpinner>
      </DModal>
    {{/if}}
  </template>
}
