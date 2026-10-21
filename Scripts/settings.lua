-- ============================================================================
-- Passive Pals settings
-- Edit values and save. The mod re-reads this file while the game runs and
-- applies the change within seconds; no restart, and it makes no difference
-- whether you edit the file in a text editor or from an in-game settings
-- screen. Every launch and every reload prints the compiled plan to UE4SS.log
-- as [PassivePals] lines, so you can see exactly what your file produced. A bad
-- value never breaks the mod: it logs one line naming the mistake and falls
-- back to the default for that entry, and a file that will not parse (a
-- half-saved file, a missing comma) leaves the settings already in force
-- exactly as they were.
-- A mod update reinstalls this file with defaults; re-apply your edits after.
--
-- If you also run the Universal Config Manager mod, every setting in this file
-- can be changed from inside the game, under Options, Mod Configs.
--
-- ---------------------------------------------------------------------------
-- HOW PAL REACTIONS WORK (what this mod edits)
-- ---------------------------------------------------------------------------
-- Every AI-driven character carries a response preset with EIGHT slots: four
-- for NOTICING someone unprovoked, four for BEING ATTACKED, each split by who
-- the other party is:
--
--   SeePlayer          it noticed you
--   SeeStronger        it noticed a non-player stronger than itself
--   SeeEqual           it noticed a non-player of similar strength
--   SeeWeaker          it noticed a non-player weaker than itself
--   AttackedByPlayer   you actually hit it
--   AttackedByStronger a stronger non-player hit it
--   AttackedByEqual    a similar-strength non-player hit it
--   AttackedByWeaker   a weaker non-player hit it
--
-- Each slot holds one REACTION:
--
--   "ignore"             Do nothing. No fight, no flight. (engine: Ignore)
--   "flee"               Run away. (engine: Escape)
--   "fight_if_winnable"  Fight, but the engine first checks relative strength;
--                        an outmatched character flees instead. This is why
--                        vanilla pals whose data says "fight back" still run
--                        from a high-level player. (engine: Battle)
--   "fight_always"       Fight, no strength check, no exceptions.
--                        (engine: Battle_Anyway)
--   "special"            Scripted interaction behavior; on docile species this
--                        is the walk-up-to-be-petted response. You will rarely
--                        set this yourself. (engine: Special)
--   "vanilla"            Leave this slot exactly as the game shipped it.
--
-- ---------------------------------------------------------------------------
-- BEHAVIOR PROFILES (bundles of the eight slots)
-- ---------------------------------------------------------------------------
-- Built-in profiles you can assign anywhere below:
--
--   "pacifist_avenger"  Never starts anything, always fights back, level gap
--                       ignored. (the mod's trademark behavior, the default)
--   "realist"           Never starts anything; fights back only when winnable,
--                       flees otherwise (vanilla's strength check kept).
--   "true_pacifist"     Never starts anything, flees when attacked.
--   "punching_bag"      Never starts anything, never reacts to anything.
--   "skittish_avenger"  Flees when it notices you, but always fights back when
--                       hit (classic Cattiva, minus the strength check).
--   "coward"            Flees from everything, always.
--   "bloodthirsty"      Attacks everything on sight and when hit, no strength
--                       check anywhere.
--   "smart_defender"    The threat-assessment profile: never starts anything;
--                       when the player attacks it, it fights only if the
--                       engine's own strength check says the fight is winnable
--                       and flees otherwise; against other attackers it flees
--                       from stronger ones and always fights equals and weaker
--                       ones. Fleeing always uses the species' native movement
--                       (runners run, fliers fly, swimmers swim; that part is
--                       engine behavior, not this mod).
--   "vanilla"           Fully untouched game behavior.
--   "custom"            The slot-by-slot profile you fill in near the bottom of
--                       this file. Every slot starts on vanilla.
--
-- You can define more of your own in behaviorProfiles; any slot you omit means
-- "vanilla" for that slot.
--
-- ---------------------------------------------------------------------------
-- ASSIGNMENT (who gets which profile; later levels win)
-- ---------------------------------------------------------------------------
--   1. the all-pals and all-humans defaults
--   2. the kind-of-character settings (alphas, rampaging predators, aggressive, ...)
--   3. byAIPreset, one exact preset at a time
--   4. speciesRules and bySpecies, one species at a time
-- ---------------------------------------------------------------------------

return {

    -- Level 1: every pal outside your control (wild, other guilds', town).
    -- Options: vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    defaultPalProfile = "pacifist_avenger",  -- The behavior every pal outside your control uses unless a rule below overrides it.

    -- Level 1: every human NPC.
    -- Options: vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    defaultHumanProfile = "vanilla",  -- The behavior every human NPC uses; vanilla keeps hostile humans dangerous and villagers normal.

    -- Some docile species walk up to you to be petted instead of reacting. That
    -- approach is stored in the same slot this mod writes, so turning this off
    -- lets your chosen profile replace it and petting approaches stop.
    preservePettingBehavior = true,  -- Keeps the walk-up-to-be-petted approach on docile species instead of overwriting it.

    -- The game weighs a character's own strength against the other party's
    -- before letting a fight happen, which is why a low-level pal you attack
    -- runs instead of fighting back. A profile decides whether its fights obey
    -- that check: "fight_if_winnable" obeys it, "fight_always" overrules it.
    -- This setting rewrites that one axis across whichever profile a character
    -- ended up with, so you can keep the game's own level behavior without
    -- giving up the profile you picked, or drop it everywhere in one line.
    --   "profile"  each profile decides for itself (the mod's own behavior)
    --   "respect"  every fight obeys the game's strength check
    --   "ignore"   no fight obeys it; nothing is ever too outmatched to fight
    -- Options: profile, respect, ignore
    levelDifference = "profile",  -- Whether a fight obeys the game's own strength check, overriding what each behavior profile says.

    -- ------------------------------------------------------------------------
    -- Level 2: by kind of character. Every one of the game's eleven AI presets
    -- belongs to exactly one of these seven settings, so between them they
    -- cover every pal and every human in the game. "default" means "use the
    -- all-pals or all-humans setting above".
    -- ------------------------------------------------------------------------

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    alphaAndBossProfile = "default",  -- Behavior for alphas and bosses; set it to vanilla to leave them exactly as dangerous as the game made them.

    -- Rampaging predators, the pals with the red aura, are alphas too, so alphaAndBossProfile
    -- covers them unless this names a profile of their own. Set it to vanilla to keep them
    -- hunting you while every other pal follows the settings above. It is applied
    -- one species at a time, so it also wins over byAIPreset; a species rule
    -- naming one predator still wins over it.
    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    rampagingPredatorProfile = "default",  -- Behavior for rampaging predators, the red-aura pals; set it to vanilla to keep them as aggressive as the game made them.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    aggressivePalProfile = "default",  -- Behavior for the pals the game tags aggressive, the ones that normally hunt you down on sight.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    skittishPalProfile = "default",  -- Behavior for the pals that normally bolt when you come near, such as Cattiva and Lifmunk.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    neutralPalProfile = "default",  -- Behavior for the pals that normally ignore you until something actually hits them.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    friendlyPalProfile = "default",  -- Behavior for the six friendly species, among them Lamball, Chikipi and Daedream.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    villagerProfile = "default",  -- Behavior for villagers, traders and police.

    -- Options: default, vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
    hostileHumanProfile = "default",  -- Behavior for the humans that attack you on sight, such as the raiders at hunter camps.

    -- ------------------------------------------------------------------------
    -- Level 4: three ready-made species rules you can fill in without opening
    -- this file, so they can be edited from the in-game settings screen. A
    -- species named here overrides every setting above. Leave a name blank to
    -- switch that rule off.
    -- ------------------------------------------------------------------------
    speciesRules = {
        rule1Species = "",  -- Species this rule applies to, written as the name your game shows you, an internal id, or a Blueprint name.
        -- Options: vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
        rule1Profile = "vanilla",  -- The behavior the species named just above uses.

        rule2Species = "",  -- Species this rule applies to, written as the name your game shows you, an internal id, or a Blueprint name.
        -- Options: vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
        rule2Profile = "vanilla",  -- The behavior the species named just above uses.

        rule3Species = "",  -- Species this rule applies to, written as the name your game shows you, an internal id, or a Blueprint name.
        -- Options: vanilla, pacifist_avenger, realist, true_pacifist, punching_bag, skittish_avenger, coward, bloodthirsty, smart_defender, custom
        rule3Profile = "vanilla",  -- The behavior the species named just above uses.
    },

    -- ------------------------------------------------------------------------
    -- The "custom" profile: build your own behavior one slot at a time, then
    -- assign "custom" to any of the settings above. A slot left on vanilla
    -- keeps the game's own reaction for that situation.
    -- ------------------------------------------------------------------------
    behaviorProfiles = {
        custom = {
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            SeePlayer = "vanilla",  -- What it does when it notices you and nothing has happened yet.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            SeeStronger = "vanilla",  -- What it does when it notices a stronger non-player character.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            SeeEqual = "vanilla",  -- What it does when it notices a non-player character of similar strength.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            SeeWeaker = "vanilla",  -- What it does when it notices a weaker non-player character.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            AttackedByPlayer = "vanilla",  -- What it does when you actually hit it.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            AttackedByStronger = "vanilla",  -- What it does when a stronger non-player character hits it.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            AttackedByEqual = "vanilla",  -- What it does when a non-player character of similar strength hits it.
            -- Options: vanilla, ignore, flee, fight_if_winnable, fight_always, special
            AttackedByWeaker = "vanilla",  -- What it does when a weaker non-player character hits it.
        },

        -- Add as many more profiles of your own here as you like. Slots you
        -- leave out stay vanilla. These names become assignable everywhere
        -- above, and a profile that reuses a built-in name replaces it.
        --
        -- Example: pals that ignore you but defend themselves only when
        -- winnable, while still fleeing stronger attackers:
        --   cautious_defender = {
        --       SeePlayer = "ignore",
        --       AttackedByPlayer = "fight_if_winnable",
        --       AttackedByStronger = "flee",
        --       AttackedByEqual = "fight_always",
        --       AttackedByWeaker = "fight_always",
        --   },
    },

    -- ------------------------------------------------------------------------
    -- Level 3: by exact AI preset, for when the seven settings above are not
    -- fine-grained enough. A preset covers every character that carries it.
    -- Authoritative counts from the game's own parameter tables (753 pal rows,
    -- 433 human rows; game build 24575825, extracted 2026-08-28, re-checked
    -- unchanged on build 25094871; species named by internal row id):
    --   BP_AIResponsePreset_friendly        6 pals: SheepBall (Lamball),
    --                                       ChickenPal (Chikipi), DreamDemon
    --                                       (Daedream), FlowerDinosaur (Dinossom),
    --                                       FlowerDinosaur_Electric, NaughtyCat
    --                                       (Grintale)
    --   BP_AIResponsePreset_escape          3 pals: Carbunclo (Lifmunk),
    --                                       MimicDog (Mimog), BeardedDragon
    --                                       (unreleased, no display name yet)
    --   BP_AIResponsePreset_Escape_to_Battle  92 pals: the skittish
    --                                       fight-back-when-cornered class
    --                                       (Cattiva/PinkCat among them)
    --   BP_AIResponsePreset_NotInterested   135 pals: indifferent until hit
    --   BP_AIResponsePreset_Warlike         167 pals (the on-sight aggressors)
    --                                       plus exactly 1 human
    --   BP_AIResponsePreset_Warlike_Anyway  1 pal: ColorfulBird
    --   BP_AIResponsePreset_Boss            347 boss/alpha spawn variants
    --   BP_AIResponsePreset_Default         no table row carries it (engine
    --                                       fallback only)
    --   BP_AIResponsePreset_Warlike_WithoutPlayer  quest-scripted: 1 pal,
    --                                       2 humans
    --   BP_AIResponsePreset_VillageNPC      253 humans (villagers, traders,
    --                                       police)
    --   BP_AIResponsePreset_Kill_All        177 hostile humans plus 1
    --                                       quest-scripted pal
    --
    -- The pal/human split is preset-granular, so two known edge effects with
    -- the default human profile: the single Warlike human follows the PAL
    -- default profile, and the quest-scripted Kill_All pal follows the HUMAN
    -- default (which keeps quest scripting vanilla; usually what you want).
    --
    -- Example: alphas and bosses stay exactly vanilla-dangerous:
    --   byAIPreset = { ["BP_AIResponsePreset_Boss"] = "vanilla" },
    byAIPreset = {},

    -- Level 4 (wins over everything): by species, any number of them. A key can
    -- be any of:
    --   the name your game shows you:        ["Lamball"] = "bloodthirsty",
    --   an internal row id:                  ["SheepBall"] = "bloodthirsty",
    --   a Blueprint name:                    ["BP_SheepBall"] = "bloodthirsty",
    -- Any of the seventeen languages Palworld ships works for the display name,
    -- so write it the way you read it in your own game. Names and row ids
    -- resolve through SpeciesReference.tsv and SpeciesNames.tsv (both shipped
    -- next to this file), straight from the game's own tables. The launch log
    -- shows each resolution; an unrecognized key logs one line and is skipped.
    -- An entry here wins over a speciesRules slot naming the same species.
    --
    -- Example: Lamballs become fearless avengers while Chikipi stay vanilla:
    --   bySpecies = {
    --       ["BP_SheepBall"] = "bloodthirsty",
    --       ["BP_ChickenPal"] = "vanilla",
    --   },
    bySpecies = {},

    -- ------------------------------------------------------------------------
    -- Diagnostics
    -- ------------------------------------------------------------------------

    -- Options: quiet, normal, verbose
    logging = "normal",  -- How much this mod writes to the UE4SS log; quiet keeps the load line, warnings and problems.

    -- How often the mod checks this file for edits while you play, so a change
    -- you save takes effect without restarting the game. Set it to 0 to stop
    -- the checking; nothing is reading the file after that, so switching it
    -- back on only takes effect the next time the game starts.
    liveReloadSeconds = 2,  -- Seconds between checks for edits to this file, from 0 to 60, where 0 turns live reloading off.

    -- Once per game start the mod asks alkeari.com for its newest published
    -- version and, only when a newer one exists, says so in the game's
    -- on-screen log. Nothing is sent but the request itself. This one is read
    -- when the game starts and again just before the notice shows, so turning
    -- it off mid-session silences a notice still pending; turning it on takes
    -- effect the next time the game starts.
    checkForUpdates = true,  -- Whether the mod tells you when a newer version of it is published.

    -- The mod waits for the game to load the AI data it rewrites and keeps
    -- trying until it succeeds. Raise these if your log says the presets never
    -- loaded this session. This wait normally ends a few seconds after launch,
    -- so pollSeconds applies to the next wait rather than to one in progress;
    -- every other setting in this file applies the moment you save.
    pollSeconds = 5,  -- Seconds between tries while the mod waits for the game to load its AI data, from 1 to 60.
    pollLimit = 120,  -- How many tries the mod makes before giving up for this session, from 10 to 600.
}
