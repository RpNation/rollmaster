import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";

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
        (left, right) => new Date(right.created_at) - new Date(left.created_at)
      )
      .map((roll) => ({
        ...roll,
        formattedCreatedAt: this.formatTimestamp(roll.created_at),
        isCurrent: this.currentRollIds.has(Number(roll.id)),
      }));
  }

  formatTimestamp(timestamp) {
    if (!timestamp) {
      return "";
    }

    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(timestamp));
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
            <article
              class="rollmaster-roll-history__entry"
              data-test-roll-history-row
            >
              <div class="rollmaster-roll-history__entry-header">
                <span
                  class={{if
                    roll.isCurrent
                    "rollmaster-roll-history__status rollmaster-roll-history__status--current"
                    "rollmaster-roll-history__status rollmaster-roll-history__status--historical"
                  }}
                  data-test-roll-history-status
                >
                  {{if
                    roll.isCurrent
                    (i18n "rollmaster.post.current")
                    (i18n "rollmaster.post.historical")
                  }}
                </span>
                <time
                  class="rollmaster-roll-history__timestamp"
                  datetime={{roll.created_at}}
                >
                  {{roll.formattedCreatedAt}}
                </time>
              </div>

              {{#if roll.desc}}
                <p class="rollmaster-roll-history__description">
                  {{roll.desc}}
                </p>
              {{/if}}

              <dl class="rollmaster-roll-history__details">
                <div class="rollmaster-roll-history__detail">
                  <dt>{{i18n "rollmaster.post.notation"}}</dt>
                  <dd data-test-roll-history-notation>{{roll.notation}}</dd>
                </div>
                <div class="rollmaster-roll-history__detail">
                  <dt>{{i18n "rollmaster.post.result"}}</dt>
                  <dd data-test-roll-history-result>{{roll.result}}</dd>
                </div>
              </dl>
            </article>
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
