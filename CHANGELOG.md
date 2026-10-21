# Changelog

## v1.5.0 - 2026-10-20

Added: once per game start the mod looks up its newest published version and tells you in the game's on-screen log, in your game's language, only when a newer one exists; checkForUpdates in settings.lua turns this off.
Added: a rampagingPredatorProfile setting for the red-aura rampaging predators, so setting it to vanilla keeps them hunting you while every other pal stays passive.
Fixed: a species rule naming an alpha, a boss, a predator or the normal form of a pal whose game Blueprint carries a suffix now reaches that pal instead of quietly doing nothing.

## v1.4.0 - 2026-09-08

Added: a levelDifference setting deciding whether a fight obeys the game's own strength check, so you can keep the level behavior the game already has without giving up the behavior profile you picked, or drop it everywhere in one line.
Added: a bySpecies entry accepts a pal's name in any of the seventeen languages the game ships, not only English, so you can write the name you actually see in your own game.
Fixed: a species rule naming a raid boss, a gym pal or a quest copy now reaches the pal it names instead of quietly doing nothing.
Fixed: a species rule written as a Blueprint name the game does not have is called out in the log instead of failing silently.
Fixed: the line the mod writes when it loads names the version you are actually running.
Fixed: if a game update ever renames one of the eight reaction slots, the preset it belongs to is left untouched and says so, instead of being half rewritten.
Fixed: the readme inside the download no longer tells you to restart the game after editing the settings file.

## v1.2.0 - 2026-09-05

Added: an edit to settings.lua applies within seconds while you play, with no restart, whether you edit the file yourself or through an in-game settings screen.
Added: a liveReloadSeconds setting choosing how often the file is checked, where 0 turns the checking off.
Fixed: a rule you remove from the settings file goes back to the game's own behavior instead of staying in force.

## v1.1.0 - 2026-09-04

- Added: seven settings that pick a behavior profile by kind of character (alphas and bosses, aggressive pals, skittish pals, neutral pals, friendly pals, villagers, hostile humans), which between them cover every character in the game.
- Added: a setting that stops the mod preserving the walk-up-to-be-petted approach on docile species, which it previously always kept.
- Added: a ready-made "custom" behavior profile with all eight reaction slots spelled out, assignable anywhere a built-in profile is.
- Added: three fill-in species rule slots, so a per-species rule can be set without writing a table by hand.
- Added: a logging setting with quiet, normal and verbose levels.
- Added: settings for how often and how many times the mod retries while it waits for the game to load its AI data.
- Changed: every setting now carries a one-sentence explanation, and any setting with a fixed set of values or a range states it next to the value.
- Changed: the retry settings moved out of the mod's code file into the settings file with everything else.

## v1.0.0 - 2026-08-28

- Added: wild pals, other guilds' pals, and town pals no longer attack the player on sight.
- Added: pals in scope no longer run away just because the player comes near; petting-type approach behavior on docile species is preserved.
- Added: pals in scope fight back when actually attacked, regardless of level difference, instead of fleeing.
- Added: humans are unaffected by default; hostile humans stay dangerous and villagers act normally, with a setting to include them.
- Added: behavior profiles, built-in and custom, assignable to all pals, all humans, individual AI presets, or individual species, controlling all eight reaction slots.
- Added: a smart_defender profile that fights only winnable fights, flees from stronger attackers, and stands up to equals and weaker ones.
- Added: per-species settings accept English display names, internal ids, or Blueprint names, backed by a shipped reference of every species.
- Added: the settings file documents the reaction system, every value, and which species carry each vanilla AI preset.
