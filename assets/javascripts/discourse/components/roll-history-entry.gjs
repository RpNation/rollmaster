import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { cancel } from "@ember/runloop";
import DButton from "discourse/components/d-button";
import discourseLater from "discourse/lib/later";
import { clipboardCopy } from "discourse/lib/utilities";
import dAgeWithTooltip from "discourse/ui-kit/helpers/d-age-with-tooltip";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class RollHistoryEntry extends Component {
  @tracked copied = false;
  #copyTimer = null;

  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this.#copyTimer);
  }

  buildBBCode() {
    const { desc, raw } = this.args.roll;
    return desc ? `[roll="${desc}"]${raw}[/roll]` : `[roll]${raw}[/roll]`;
  }

  @action
  async copyBBCode() {
    await clipboardCopy(this.buildBBCode());
    cancel(this.#copyTimer);
    this.copied = true;
    this.#copyTimer = discourseLater(() => (this.copied = false), 2000);
  }

  <template>
    <blockquote
      class={{dConcatClass
        "bb-rollmaster-result"
        "rollmaster-roll-history__roll"
        (unless @roll.isCurrent "--historical")
      }}
      data-test-roll-history-row
      data-test-roll-history-status={{if
        @roll.isCurrent
        "current"
        "historical"
      }}
      ...attributes
    >
      <p class="bb-rollmaster-title">
        <span class="bb-rollmaster-description">
          {{dIcon "rollmaster-dices"}}
          {{if @roll.desc @roll.desc (i18n "rollmaster.bbcode.default")}}:
        </span>
        <span class="bb-rollmaster-notation">{{@roll.notation}}</span>
        <span class="rollmaster-roll-history__title-meta">
          {{#unless @roll.isCurrent}}
            <span
              class="rollmaster-roll-history__historical-indicator"
              aria-label={{i18n "rollmaster.post.historical_tooltip"}}
              title={{i18n "rollmaster.post.historical_tooltip"}}
            >
              {{dIcon "far-eye-slash"}}
              <span class="sr-only">{{i18n "rollmaster.post.historical"}}</span>
            </span>
          {{else}}
            <span class="sr-only">{{i18n "rollmaster.post.current"}}</span>
          {{/unless}}
          <span class="rollmaster-roll-history__timestamp">
            {{dAgeWithTooltip @roll.created_at}}
          </span>
        </span>
      </p>
      <div class="rollmaster-roll-history__result-row">
        <p class="bb-rollmaster-results">{{@roll.result}}</p>
        <DButton
          @class="btn-flat btn-small"
          @action={{this.copyBBCode}}
          @icon={{if this.copied "check" "copy"}}
          @title={{if
            this.copied
            "rollmaster.post.copied"
            "rollmaster.post.copy"
          }}
          data-test-copy-bbcode
        />
      </div>
    </blockquote>
  </template>
}
