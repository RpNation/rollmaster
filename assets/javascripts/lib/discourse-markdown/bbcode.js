import { i18n } from "discourse-i18n";

const ROLL_CLASS = "bb-rollmaster";
const DATA_DICE = "data-notation";

function applyRollAttrs(state, token, attrs, content) {
  token.attrs = [
    ["class", ROLL_CLASS],
    [DATA_DICE, content],
  ];

  if (content) {
    token = state.push("text", "", 0);
    token.content = i18n("rollmaster.bbcode.placeholder") + content;
  }
}

const blockRule = {
  tag: "roll",
  replace(state, tagInfo, content) {
    let token = state.push("roll_open", "div", 1);

    applyRollAttrs(state, token, tagInfo.attrs, content);

    state.push("roll_close", "div", -1);
    return true;
  },
};

const inlineRule = {
  tag: "roll",
  replace(state, tagInfo, content) {
    let token = state.push("roll_open", "span", 1);

    applyRollAttrs(state, token, tagInfo.attrs, content);

    state.push("roll_close", "span", -1);
    return true;
  },
};

export function setup(helper) {
  helper.allowList(["div.bb-rollmaster", "span.bb-rollmaster"]);

  helper.registerOptions((opts) => {
    opts.features["rollmaster"] = true;
  });

  helper.registerPlugin((md) => {
    md.inline.bbcode.ruler.push("inline-roll", inlineRule);
    md.block.bbcode.ruler.push("block-roll", blockRule);
  });
}
