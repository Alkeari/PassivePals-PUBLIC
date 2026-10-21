# Manual verification

Run after `tools\deploy.ps1 -Package` and a Palworld relaunch, and record the build id it ran on.

1. Walk near vanilla-aggressive species (Warlike/Boss carriers: LizardMan, BirdDragon, alphas): no unprovoked attack.
2. Walk near vanilla-skittish species (Escape_to_Battle carriers: Cattiva/PinkCat): no fleeing.
3. Attack a low-level pal with a high-level character, with PalLevelScaling disabled: it fights back instead of fleeing (this is the level-gate bypass working).
4. Confirm petting on docile species (Lamball/SheepBall) still works (Special preserved).
5. With default settings, humans stay vanilla: hostile humans (Hunter camps) still attack on sight, villagers behave normally. With `defaultHumanProfile = "pacifist_avenger"`, they follow the pal rules.
6. Another faction's pals follow the pal rules.
7. Own pals and base workers behave unchanged.
8. Settings honored: the launch log's plan block reflects the settings file; a `byAIPreset` entry of "vanilla" leaves that preset's carriers vanilla in-game.
9. Live reload: edit `settings.lua` while the game runs; within `liveReloadSeconds` the log shows one "settings reloaded" line naming what changed plus the new plan, and the change is visible in-game. Save a half-written file: one warning, settings unchanged.
10. Species layer: a `bySpecies` entry makes only that species behave differently, and the per-sensor preset it constructs does not leak to other species.
11. With clean default settings, no unprovoked pal-versus-pal combat occurs (all Discover slots in scope are Ignore); inter-pal fights only ever follow an actual hit.
12. `bySpecies` keys resolve from display name ("Lamball"), row id ("SheepBall"), and Blueprint name ("BP_SheepBall") alike, per the launch log's resolution lines.
