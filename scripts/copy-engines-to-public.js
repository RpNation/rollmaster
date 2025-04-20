const { copyFileSync } = require("node:fs");

copyFileSync(
  "node_modules/mathjs/lib/browser/math.js",
  "public/vendors/math.js"
);
copyFileSync(
  "node_modules/random-js/dist/random-js.umd.min.js",
  "public/vendors/random-js.min.js"
);
copyFileSync(
  "node_modules/@dice-roller/rpg-dice-roller/lib/umd/bundle.min.js",
  "public/vendors/rpg-dice-roller.min.js"
);
