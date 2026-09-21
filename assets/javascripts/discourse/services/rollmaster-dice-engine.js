import Service from "@ember/service";
import loadScript from "discourse/lib/load-script";

/* global rpgDiceRoller */

export default class RollmasterDiceEngine extends Service {
  #cache = new Map();

  getCachedValidation(notation) {
    return this.#cache.get(notation);
  }

  // Roll (not just parse) to match server-side behavior. Cached per notation string
  async validate(notation) {
    if (this.#cache.has(notation)) {
      return this.#cache.get(notation);
    }

    await this.#load();

    let error = null;
    try {
      new rpgDiceRoller.DiceRoller().roll(notation);
    } catch (err) {
      error = err.message;
    }

    this.#cache.set(notation, error);
    return error;
  }

  async #load() {
    await Promise.all([
      loadScript("/plugins/rollmaster/vendors/math.js"),
      loadScript("/plugins/rollmaster/vendors/random-js.min.js"),
    ]);
    return await loadScript(
      "/plugins/rollmaster/vendors/rpg-dice-roller.min.js"
    );
  }
}
