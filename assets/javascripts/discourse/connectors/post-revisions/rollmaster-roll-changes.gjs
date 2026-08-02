import Component from "@glimmer/component";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class RollmasterRollChanges extends Component {
  static shouldRender(outletArgs) {
    return (
      outletArgs.model.roll_changes?.previous?.length ||
      outletArgs.model.roll_changes?.current?.length
    );
  }

  get previousRolls() {
    return this.args.outletArgs.model.roll_changes?.previous || [];
  }

  get currentRolls() {
    return this.args.outletArgs.model.roll_changes?.current || [];
  }

  <template>
    <div class="row rollmaster-revision-rolls" data-test-roll-revision-changes>
      <div class="revision-content --previous" data-test-roll-revision-previous>
        <p class="rollmaster-revision-rolls__heading">
          {{i18n "rollmaster.revisions.title"}}
        </p>

        {{#if this.previousRolls.length}}
          <ul class="rollmaster-revision-rolls__list">
            {{#each this.previousRolls as |roll|}}
              <li class="rollmaster-revision-rolls__entry">
                {{#if roll.desc}}
                  <span class="rollmaster-revision-rolls__description">
                    {{roll.desc}}:
                  </span>
                {{/if}}
                <span class="rollmaster-revision-rolls__notation">
                  {{roll.notation}}
                </span>
                <span class="rollmaster-revision-rolls__result">
                  {{roll.result}}
                </span>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p class="rollmaster-revision-rolls__empty">
            {{i18n "rollmaster.revisions.empty"}}
          </p>
        {{/if}}
      </div>

      {{#if (or this.previousRolls.length this.currentRolls.length)}}
        <div class="rollmaster-revision-rolls__arrow">&rarr;</div>
      {{/if}}

      <div class="revision-content --current" data-test-roll-revision-current>
        <p class="rollmaster-revision-rolls__heading">
          {{i18n "rollmaster.revisions.title"}}
        </p>

        {{#if this.currentRolls.length}}
          <ul class="rollmaster-revision-rolls__list">
            {{#each this.currentRolls as |roll|}}
              <li class="rollmaster-revision-rolls__entry">
                {{#if roll.desc}}
                  <span class="rollmaster-revision-rolls__description">
                    {{roll.desc}}:
                  </span>
                {{/if}}
                <span class="rollmaster-revision-rolls__notation">
                  {{roll.notation}}
                </span>
                <span class="rollmaster-revision-rolls__result">
                  {{roll.result}}
                </span>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p class="rollmaster-revision-rolls__empty">
            {{i18n "rollmaster.revisions.empty"}}
          </p>
        {{/if}}
      </div>
    </div>
  </template>
}
