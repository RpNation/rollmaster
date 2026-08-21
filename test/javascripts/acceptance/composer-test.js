import { click,fillIn, visit, waitUntil  } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Rollmaster - composer", function (needs) {
  needs.user();
  needs.site({ can_tag_topics: true });
  needs.settings({
    bbcode_enabled: false, // overlap with other plugins. for local dev
    rollmaster_enabled: true,
    allow_uncategorized_topics: true,
  });

  test("bbcode [roll] renders a blockquote in preview", async function (assert) {
    await visit("/");
    await click("#create-topic");

    await fillIn(".d-editor-input", "hello world");
    assert.dom(".d-editor-preview").hasText("hello world");

    await fillIn(".d-editor-input", "[roll]2d20[/roll]");

    assert
      .dom(".d-editor-preview blockquote.bb-rollmaster-result")
      .hasAttribute("data-notation", "2d20", "blockquote has data-notation");
    assert
      .dom(".d-editor-preview .bb-rollmaster-results")
      .hasText("???", "results show placeholder before validation");
  });

  test("[roll] valid notation does not show error state", async function (assert) {
    await visit("/");
    await click("#create-topic");

    await fillIn(".d-editor-input", "[roll]2d20[/roll]");

    await waitUntil(
      () =>
        !document
          .querySelector(
            ".d-editor-preview blockquote.bb-rollmaster-result:not(.--error) .bb-rollmaster-results"
          )
          ?.textContent.includes("???") ||
        document.querySelector(
          ".d-editor-preview blockquote.bb-rollmaster-result"
        ),
      { timeout: 5000 }
    );

    assert
      .dom(".d-editor-preview blockquote.bb-rollmaster-result")
      .doesNotHaveClass("--error", "valid notation has no error state");
  });

  test("[roll] invalid notation shows error state", async function (assert) {
    await visit("/");
    await click("#create-topic");

    await fillIn(".d-editor-input", "[roll]junk[/roll]");

    await waitUntil(
      () =>
        document.querySelector(
          ".d-editor-preview blockquote.bb-rollmaster-result.--error"
        ),
      { timeout: 5000 }
    );

    assert
      .dom(".d-editor-preview blockquote.bb-rollmaster-result")
      .hasClass("--error", "invalid notation shows error state");
  });
});
