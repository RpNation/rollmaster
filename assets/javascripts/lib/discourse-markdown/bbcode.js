import { i18n } from "discourse-i18n";

const ROLL_CLASS = "bb-rollmaster";

function applyRollAttrs(state, token, attrs, content) {
  token.attrs = [
    ["class", ROLL_CLASS],
    ["data-notation", content],
  ];

  if (attrs._default) {
    token.attrs.push(["data-desc", attrs._default]);
  }

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

  helper.registerOptions((opts, siteSettings) => {
    opts.features["rollmaster"] = !!siteSettings.rollmaster_enabled;
  });

  helper.registerPlugin((md) => {
    if (!md.options.discourse.features["rollmaster"]) {
      return;
    }

    md.inline.bbcode.ruler.push("inline-roll", inlineRule);
    md.block.bbcode.ruler.push("block-roll", blockRule);
  });
}
