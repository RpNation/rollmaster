import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Rollmaster - composer", function (needs) {
  needs.user();
  needs.site({ can_tag_topics: true });
  needs.settings({
    bbcode_enabled: false, // overlap with other plugins. for local dev
    rollmaster_enabled: true,
    allow_uncategorized_topics: true,
  });

  test("bbcode [roll] is rendered", async function (assert) {
    await visit("/");
    await click("#create-topic");

    await fillIn(".d-editor-input", "hello world");

    assert.dom(".d-editor-preview").hasText("hello world");

    await fillIn(".d-editor-input", "[roll]test[/roll]");

    assert
      .dom(".d-editor-preview .bb-rollmaster")
      .hasAttribute("data-notation", "test");

    await fillIn(".d-editor-input", "[roll]2d20[/roll]");

    assert
      .dom(".d-editor-preview .bb-rollmaster")
      .hasAttribute("data-notation", "2d20");
  });

  test("[roll] notation is validated", async function (assert) {
    await visit("/");
    await click("#create-topic");

    await fillIn(".d-editor-input", "hello world");

    assert.dom(".d-editor-preview").hasText("hello world");
    assert.dom(".rollmaster-valid-composer").doesNotExist();

    await fillIn(".d-editor-input", "[roll]2d20[/roll]");

    assert.dom(".rollmaster-valid-composer").exists();
    assert
      .dom(".rollmaster-valid-composer")
      .hasAttribute("title", i18n("rollmaster.validator.success"));

    await fillIn(".d-editor-input", "[roll]junk[/roll]");
    assert.dom(".rollmaster-valid-composer").exists();
    assert
      .dom(".rollmaster-valid-composer")
      .hasAttribute("title", i18n("rollmaster.validator.error"));
    assert.dom(".rollmaster-valid-composer .roll__invalid").exists();
  });
});
