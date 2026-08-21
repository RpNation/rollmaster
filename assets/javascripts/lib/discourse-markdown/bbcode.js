const BLOCK_CLASS = "bb-rollmaster-result";
const RESULTS_PLACEHOLDER = "???";

function buildRollTokens(state, tagInfo, content) {
  const notation = content?.trim();
  const desc = tagInfo.attrs._default || null;

  if (!notation) {
    return false;
  }

  let token;

  token = state.push("rollmaster_open", "blockquote", 1);
  token.attrs = [
    ["class", BLOCK_CLASS],
    ["data-notation", notation],
  ];
  if (desc) {
    token.attrs.push(["data-desc", desc]);
  }

  token = state.push("rollmaster_title_open", "p", 1);
  token.attrs = [["class", "bb-rollmaster-title"]];

  token = state.push("rollmaster_desc_open", "span", 1);
  token.attrs = [["class", "bb-rollmaster-description"]];
  if (desc) {
    token = state.push("text", "", 0);
    token.content = `${desc}:`;
  }
  state.push("rollmaster_desc_close", "span", -1);

  token = state.push("rollmaster_notation_open", "span", 1);
  token.attrs = [["class", "bb-rollmaster-notation"]];
  token = state.push("text", "", 0);
  token.content = notation;
  state.push("rollmaster_notation_close", "span", -1);

  state.push("rollmaster_title_close", "p", -1);

  token = state.push("rollmaster_results_open", "p", 1);
  token.attrs = [["class", "bb-rollmaster-results"]];
  token = state.push("text", "", 0);
  token.content = RESULTS_PLACEHOLDER;
  state.push("rollmaster_results_close", "p", -1);

  state.push("rollmaster_close", "blockquote", -1);

  return true;
}

const blockRule = {
  tag: "roll",
  replace(state, tagInfo, content) {
    return buildRollTokens(state, tagInfo, content);
  },
};

const inlineRule = {
  tag: "roll",
  replace(state, tagInfo, content) {
    return buildRollTokens(state, tagInfo, content);
  },
};

export function setup(helper) {
  helper.allowList([
    "blockquote.bb-rollmaster-result",
    "blockquote[data-notation]",
    "blockquote[data-desc]",
    "p.bb-rollmaster-title",
    "p.bb-rollmaster-results",
    "span.bb-rollmaster-description",
    "span.bb-rollmaster-notation",
  ]);

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
