# Rollmaster

A Discourse dice rolling plugin, with support for in-post roll history. Powered by the [RPG Dice Roller](https://dice-roller.github.io/documentation/) library.

For more information, please see: **url to meta topic**

---

This is a dice rolling plugin, using the amazing [RPG Dice Roller](https://dice-roller.github.io/documentation/) library. Users use the `[roll]` BBCode tag to roll in post.

```bbcode
[roll]4d20[/roll]

[roll="description of the roll"]4d10r<=3[/roll]
```

Notation of the dice rolls can be found at [RPG Dice Roller: Notation](https://dice-roller.github.io/documentation/guide/notation/), which supports modifiers (rerolls, fudge dice, fate dice, criticals, etc.), math (max/min, sorting, etc.), group rolls, and more.

All rolls are saved and stored in the post history, and can be pulled up for each post, regardless of what the final cooked HTML displays. All rolls are reused in the same post, allowing users to freely edit the contents of their post (or fix their roll notation), while minimizing abuse. For example, suppose a user already rolled `1d20 = 14` using `[roll]1d20[/roll]` in their post. If the post is editted, and the `[roll]1d20[/roll]` remains the same, the plugin will reuse the previous `1d20 = 14` result. If the notation changes, a new roll is made. Changing the description of the roll won't create a reroll either.

If multiple rolls are made in the same post, using the same notation, the plugin will create new rolls for each instance. Upon editing the post, the plugin will match and reuse the rolls in the order they appear in the post.

All rolls made for a post are saved, and displayed in both the post history, and in a separate "Rolls" button in the post actions. This way, if a post has been modified, any user can see the history for any sign of abuse. Restoring an existing roll is as easy as reusing the notation.

