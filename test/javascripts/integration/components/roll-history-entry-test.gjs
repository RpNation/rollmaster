import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import RollHistoryEntry from "discourse/plugins/rollmaster/discourse/components/roll-history-entry";

function baseRoll(overrides = {}) {
  return {
    id: 1,
    raw: "2d6",
    notation: "2d6",
    result: "4",
    desc: null,
    created_at: "2024-01-01T00:00:00Z",
    isCurrent: true,
    ...overrides,
  };
}

module("Integration | Component | RollHistoryEntry", function (hooks) {
  setupRenderingTest(hooks);

  test("renders notation and result", async function (assert) {
    const roll = baseRoll();

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);

    assert.dom(".bb-rollmaster-notation").hasText("2d6", "notation is shown");
    assert.dom(".bb-rollmaster-results").includesText("4", "result is shown");
  });

  test("uses default label when no description", async function (assert) {
    const roll = baseRoll();

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);

    assert
      .dom(".bb-rollmaster-description")
      .includesText("Roll:", "default label shown when no desc");
  });

  test("shows description when provided", async function (assert) {
    const roll = baseRoll({ desc: "Strength check" });

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);

    assert
      .dom(".bb-rollmaster-description")
      .includesText("Strength check:", "provided description is shown");
  });

  test("current roll has no historical marker or modifier", async function (assert) {
    const roll = baseRoll({ isCurrent: true });

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);

    assert
      .dom("blockquote")
      .doesNotHaveClass(
        "--historical",
        "no --historical class on current roll"
      );
    assert
      .dom(".rollmaster-roll-history__historical-indicator")
      .doesNotExist("no historical indicator on current roll");
  });

  test("historical roll has --historical class and indicator", async function (assert) {
    const roll = baseRoll({ isCurrent: false });

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);

    assert
      .dom("blockquote")
      .hasClass("--historical", "blockquote has --historical class");
    assert
      .dom(".rollmaster-roll-history__historical-indicator")
      .exists("historical indicator is shown");
  });

  test("copies plain BBCode when no description", async function (assert) {
    const writeText = sinon.stub().resolves();
    sinon.stub(window.navigator, "clipboard").get(() => ({ writeText }));

    const roll = baseRoll({ raw: "1d20", notation: "1d20" });

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);
    await click("[data-test-copy-bbcode]");

    assert.true(
      writeText.calledWithExactly("[roll]1d20[/roll]"),
      "plain BBCode copied without description"
    );
  });

  test("copies BBCode with description when desc is set", async function (assert) {
    const writeText = sinon.stub().resolves();
    sinon.stub(window.navigator, "clipboard").get(() => ({ writeText }));

    const roll = baseRoll({
      raw: "1d20",
      notation: "1d20",
      desc: "Attack roll",
    });

    await render(<template><RollHistoryEntry @roll={{roll}} /></template>);
    await click("[data-test-copy-bbcode]");

    assert.true(
      writeText.calledWithExactly('[roll="Attack roll"]1d20[/roll]'),
      "BBCode with description copied"
    );
  });
});
