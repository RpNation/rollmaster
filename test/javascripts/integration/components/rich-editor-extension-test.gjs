import { module, test } from "qunit";
import {
  registerRichEditorExtension,
  resetRichEditorExtensions,
} from "discourse/lib/composer/rich-editor-extensions";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { testMarkdown } from "discourse/tests/helpers/rich-editor-helper";
import { extension } from "discourse/plugins/rollmaster/discourse/initializers/rich-editor-extension";

module(
  "Integration | Component | prosemirror-editor - rollmaster extension",
  function (hooks) {
    setupRenderingTest(hooks);

    // The registry is a module-level array, and anything calling resetRichEditorExtensions()
    // (acceptance tests do, on teardown) restores only the core defaults -- dropping this
    // plugin's extension, since its initializer won't run again. Re-register per test so these
    // don't depend on running before any acceptance test.
    hooks.beforeEach(async function () {
      this.siteSettings.rollmaster_enabled = true;
      await resetRichEditorExtensions();
      registerRichEditorExtension(extension);
    });

    hooks.afterEach(() => resetRichEditorExtensions());

    test("roll with a description round-trips", async function (assert) {
      const markdown = `[roll="Attack"]1d20+5[/roll]\n\n`;

      await testMarkdown(
        assert,
        markdown,
        (a) => {
          const node = document.querySelector(
            ".ProseMirror .composer-roll-node"
          );
          a.dom(".bb-rollmaster-description", node).hasText("Attack");
          a.dom(".bb-rollmaster-notation", node).hasText("1d20+5");
          a.dom(".composer-roll-node__icon", node).exists();
        },
        markdown
      );
    });

    test("roll without a description round-trips", async function (assert) {
      const markdown = `[roll]1d6[/roll]\n\n`;

      await testMarkdown(
        assert,
        markdown,
        (a) => {
          const node = document.querySelector(
            ".ProseMirror .composer-roll-node"
          );
          // The description field is always rendered so it can be filled in, but stays empty
          // and must not serialize back as `[roll=""]`.
          a.dom(".bb-rollmaster-description", node).hasNoText();
          a.dom(".bb-rollmaster-notation", node).hasText("1d6");
        },
        markdown
      );
    });

    test("inline roll splits the surrounding paragraph", async function (assert) {
      const markdown = `Before text [roll]1d6[/roll] after text\n\n`;

      await testMarkdown(
        assert,
        markdown,
        (a) => {
          const paragraphs = [
            ...document.querySelectorAll(".ProseMirror > p"),
          ].map((p) => p.textContent);
          a.deepEqual(paragraphs, ["Before text ", " after text"]);

          const node = document.querySelector(
            ".ProseMirror .composer-roll-node"
          );
          a.dom(".bb-rollmaster-notation", node).hasText("1d6");
        },
        "Before text \n\n[roll]1d6[/roll]\n\n after text"
      );
    });

    test("inline roll at the end of a line leaves a trailing empty paragraph", async function (assert) {
      const markdown = `Before text [roll]1d6[/roll]\n\n`;

      await testMarkdown(
        assert,
        markdown,
        (a) => {
          const paragraphs = [
            ...document.querySelectorAll(".ProseMirror > p"),
          ].map((p) => p.textContent);
          a.deepEqual(paragraphs, ["Before text ", ""]);
        },
        "Before text \n\n[roll]1d6[/roll]\n\n"
      );
    });

    test("empty fields get placeholders", async function (assert) {
      const markdown = `[roll]1d6[/roll]\n\n`;

      await testMarkdown(
        assert,
        markdown,
        (a) => {
          const node = document.querySelector(
            ".ProseMirror .composer-roll-node"
          );
          a.dom(".bb-rollmaster-description", node).hasAttribute(
            "data-placeholder"
          );
          // The notation is filled in, so it must not be showing a placeholder.
          a.dom(".bb-rollmaster-notation", node).doesNotHaveAttribute(
            "data-placeholder"
          );
        },
        markdown
      );
    });
  }
);
