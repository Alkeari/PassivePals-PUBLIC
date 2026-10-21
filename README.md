# Passive Pals

Wild pals stop hunting you down while you are just traveling, and stop bolting the moment you walk near. Hit one and it fights back instead of running, however far below you it is.

> **Host side. The world's host decides, and only the host installs it.**

---

## Availability

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3791931809)
- [Nexus Mods](https://www.nexusmods.com/palworld/mods/5445)

## What It Does

- **Nothing attacks you unprovoked** - wild pals, other guilds' pals and town pals all stop starting fights, whether or not the game tags them aggressive.
- **Nothing runs from you either** - under the default profile they stay put as you walk past instead of scattering across the map.
- **Hit something and it hits back** - an attacked pal turns on its attacker rather than fleeing, even when it is far below your level.
- **Level difference is yours to keep or drop** - the game's own strength check, the one that sends an outmatched pal running instead of fighting, can be switched back on or off across whatever profile you picked.
- **Petting still works** - the docile species that walk up to be petted keep doing it. One setting hands them your profile instead.
- **Humans are left alone** - hostile humans stay dangerous and villagers behave normally, until you decide otherwise.
- **Tune it as far as you want** - nine ready-made behavior profiles, or your own, aimed at every pal, one kind of character, one AI preset, or one species.
- **It fails quietly** - if a Palworld update moves what it relies on, that part turns itself off and logs a line instead of crashing your game.

---

## Requirements

- Palworld on Steam. The Microsoft Store and Game Pass builds are not supported.

## Installation

Install it on the machine that runs the world: your own game in singleplayer, the host's in co-op, or the dedicated server.

## Configuration

Edit `Scripts\settings.lua` inside the mod folder and save it. Changes take effect within a couple of seconds while you play; no restart.

The `liveReloadSeconds` setting sets how often the file is checked, and 0 turns the checking off.

The file is the manual: it explains the eight reaction slots the game's AI actually uses, every value they accept, and all eleven of the game's own AI presets. An update reinstalls it with defaults, so keep a copy of your edits.

| What you can change | Settings |
|---|---|
| Behavior profiles | nine ready-made bundles, a blank `custom` laid out for you, and as many of your own as you like |
| Every pal, every human | one default profile for each, so humans stay vanilla unless you say otherwise |
| By kind of character | alphas and bosses, rampaging predators (the red-aura pals), aggressive, skittish, neutral and friendly pals, villagers, hostile humans |
| By AI preset | a profile aimed at one of the game's own eleven presets |
| By species | keyed by the name your own game shows you, in any of its seventeen languages, or by internal id or Blueprint name, with three slots ready to fill in |
| Level difference | whether a fight obeys the game's own strength check, on top of whatever profile applies |
| Petting | whether docile species keep walking up to be petted |
| Logging | quiet, normal or verbose, and how hard the mod retries while the game loads its AI data |
| Update notice | `checkForUpdates`: once per game start, read the newest published version of this mod from `alkeari.com/updates/passive-pals.json` and tell you in the game's on-screen log only when a newer one exists. Nothing is sent but that one request |

The nine ready-made profiles are `pacifist_avenger` (the default), `smart_defender`, `realist`, `true_pacifist`, `punching_bag`, `skittish_avenger`, `coward`, `bloodthirsty` and `vanilla`. Most specific assignment wins: species beats AI preset, which beats kind of character, which beats the global default.

To keep rampaging predators hunting you while every other pal leaves you alone, set `rampagingPredatorProfile` to `vanilla`. It applies to each predator as a species, so it also wins over a rule for their AI preset.

`levelDifference` sits on top of all of it: leave it on `profile` and each profile decides for itself, set it to `respect` and every fight obeys the game's own strength check, set it to `ignore` and none of them do.

Every setting is also on the Mod Configs tab of [Universal Config Manager](https://www.nexusmods.com/palworld/mods/5545) if you run it, so you can change them without leaving the game. It is entirely optional and this mod never requires it.

## Compatibility

- **Host side.** Pal behavior is decided where the world lives: your game in singleplayer, the host's in co-op, the dedicated server otherwise. Its settings apply to everyone in that world.
- **Client side: none.** A joining player does not need the mod, and a copy on their machine changes nothing about how the pals behave.
- Any other mod that rewrites the game's shared AI reaction presets conflicts with this one. Run one of them.
- A setting the mod cannot read keeps its default and says so in `UE4SS.log`.
- If a Palworld update renames something the mod depends on, it disables that part and logs one line instead of crashing. Wait for an update rather than reporting a crash.

## License

License terms are in the [Alkeari License Agreement](https://gist.github.com/Alkeari/2c6ec0cdf3dafee375b1a00b28ca190a).
