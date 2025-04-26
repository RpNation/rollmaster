/**
 * This file is designed to allow devs to debug rpg-dice-roller in a standalone nodejs environment.
 * Users are advised to start a new nodejs process with the command:
 *
 * node ./scripts/debug.js
 *
 * This will start a new nodejs REPL with the rpg-dice-roller library loaded.
 */
const repl = require("node:repl");
const { DiceRoller } = require("@dice-roller/rpg-dice-roller");

function roll(...diceRolls) {
  const roller = new DiceRoller();
  try {
    roller.roll(...diceRolls);
    return roller.log;
  } catch (e) {
    return {
      type: "error",
      name: e.name,
      msg: e.message,
    };
  }
}

const r = repl.start({ prompt: "> " });
r.context.roll = roll;
r.context.DiceRoller = DiceRoller;
