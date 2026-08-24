import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import RollNodeView from "../components/roll-node-view";

function escapeQuotes(text) {
  return text.replace(/"/g, "“");
}

/** @type {RichEditorExtension} */
export const extension = {
  nodeSpec: {
    roll: {
      group: "block",
      content: "roll_desc roll_notation roll_results?",
      defining: true,
      isolating: true,
      parseDOM: [{ tag: "blockquote.bb-rollmaster-result" }],
      toDOM: () => ["blockquote", { class: "bb-rollmaster-result" }, 0],
    },
    roll_desc: {
      content: "text*",
      marks: "",
      parseDOM: [{ tag: "p.bb-rollmaster-description" }],
      toDOM: () => ["p", { class: "bb-rollmaster-description" }, 0],
    },
    roll_notation: {
      content: "text*",
      marks: "",
      parseDOM: [{ tag: "p.bb-rollmaster-notation" }],
      toDOM: () => ["p", { class: "bb-rollmaster-notation" }, 0],
    },
    // Carries the "???" placeholder from the cook. The NodeView renders live validation instead.
    roll_results: {
      content: "text*",
      marks: "",
      selectable: false,
      parseDOM: [{ tag: "p.bb-rollmaster-results" }],
      toDOM: () => [
        "p",
        { class: "bb-rollmaster-results", style: "display: none" },
        0,
      ],
    },
  },

  nodeViews: {
    roll: {
      component: RollNodeView,
      hasContent: true,
    },
  },

  parse: {
    // `[roll]` can be inline as a QoL for markdown mode. A block-group node can't nest inside a
    // paragraph's inline-only content, so when that happens: force-close the paragraph, and
    // make the roll block a sibling
    rollmaster_open(state) {
      if (state.top().type.name === "paragraph") {
        state.closeNode();
        state.rollmasterReopenParagraph = true;
      }

      state.openNode(state.schema.nodes.roll);
    },
    rollmaster_close(state) {
      state.closeNode();

      if (state.rollmasterReopenParagraph) {
        state.openNode(state.schema.nodes.paragraph);
        state.rollmasterReopenParagraph = false;
      }
    },
    rollmaster_title: { ignore: true },
    rollmaster_desc_open(state, token, tokens, i) {
      const next = tokens[i + 1];

      if (next?.type === "text") {
        next.content = next.content.replace(/:$/, "");
      }

      state.openNode(state.schema.nodes.roll_desc);
      return true;
    },
    rollmaster_desc_close(state) {
      state.closeNode();
      return true;
    },
    rollmaster_notation: { block: "roll_notation" },
    rollmaster_results: { block: "roll_results" },
  },

  // Converts `[roll]`, `[roll=desc]`, `[roll="desc"]`, or `[roll='desc']` into the node when typed
  inputRules: ({ pmState: { TextSelection } }) => ({
    match: /\[roll(?:="([^"]*)"|='([^']*)'|=([^\]"']+))?\]$/,
    handler: (state, match, start, end) => {
      const { schema } = state;
      const tr = state.tr;
      const desc = match[1] ?? match[2] ?? match[3] ?? "";

      const descNode = desc
        ? schema.nodes.roll_desc.create(null, schema.text(desc))
        : schema.nodes.roll_desc.create();
      const notationNode = schema.nodes.roll_notation.create();

      tr.replaceWith(
        start,
        end,
        schema.nodes.roll.create(null, [descNode, notationNode])
      );

      // A typed description is already filled in, so jump straight to the (empty) notation
      // field; otherwise drop the caret into the description so the author fills top-down.
      const caret = desc ? start + descNode.nodeSize + 2 : start + 2;
      tr.setSelection(TextSelection.create(tr.doc, caret));

      return tr;
    },
  }),

  // Mirrors core's placeholder extension: decorate the empty description/notation fields with
  // data-placeholder, which the stylesheet renders via ::before.
  plugins({
    pmState: { Plugin, PluginKey },
    pmView: { Decoration, DecorationSet },
  }) {
    const placeholders = {
      roll_desc: i18n("rollmaster.composer.description_placeholder"),
      roll_notation: i18n("rollmaster.composer.notation_placeholder"),
    };

    return new Plugin({
      key: new PluginKey("rollmaster-placeholders"),
      props: {
        decorations(state) {
          const decorations = [];

          state.doc.descendants((node, pos) => {
            const placeholder = placeholders[node.type.name];

            // nodeSize === 2 is an empty textblock (open + close, no content).
            if (placeholder && node.nodeSize === 2) {
              decorations.push(
                Decoration.node(pos, pos + node.nodeSize, {
                  "data-placeholder": placeholder,
                })
              );
            }
          });

          return DecorationSet.create(state.doc, decorations);
        },
      },
    });
  },

  // Backs the composer toolbar button when the rich editor is active.
  commands: ({ schema, pmState: { TextSelection } }) => ({
    insertRoll() {
      return (state, dispatch) => {
        // createAndFill supplies the empty description/notation fields, which render their
        // placeholders until the author types.
        const roll = schema.nodes.roll.createAndFill();

        if (!roll) {
          return false;
        }

        if (dispatch) {
          const { from } = state.selection;
          const tr = state.tr.replaceSelectionWith(roll);

          // +2 steps into the roll and then into the description; `near` snaps to the closest
          // valid text position if the insert shifted things.
          tr.setSelection(TextSelection.near(tr.doc.resolve(from + 2)));
          dispatch(tr.scrollIntoView());
        }

        return true;
      };
    },
  }),

  serializeNode: {
    roll(state, node) {
      let desc = "";
      let notation = "";

      node.forEach((child) => {
        if (child.type.name === "roll_desc") {
          desc = child.textContent;
        } else if (child.type.name === "roll_notation") {
          notation = child.textContent;
        }
      });

      state.write(desc ? `[roll="${escapeQuotes(desc)}"]` : "[roll]");
      state.write(notation);
      state.write("[/roll]\n\n");
    },
  },
};

export default {
  name: "rollmaster-rich-editor-extension",
  initialize() {
    withPluginApi((api) => {
      api.registerRichEditorExtension(extension);
    });
  },
};
