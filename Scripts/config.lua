local config = {}

-- EPalAIResponseType, confirmed on build 24575825.
config.response = {
    Ignore = 0,
    Escape = 1,
    Battle = 2,
    Special = 3,
    Battle_Anyway = 4,
}

config.discoverProps = {
    "Discover_Player", "Discover_Greater", "Discover_Equal", "Discover_Smaller",
}

config.damagedProps = {
    "Damaged_Player", "Damaged_Greater", "Damaged_Equal", "Damaged_Smaller",
}

-- Presets only ever observed on human NPCs (build 24575825): exempted by default so the
-- mod targets pals, not humans. The split is preset-granular; a pal observed carrying one
-- of these would be a new finding.
config.humanPresetNames = {
    "BP_AIResponsePreset_VillageNPC",
    "BP_AIResponsePreset_Kill_All",
}

-- The sensor decision function (script-VM-called, verified firing) used by the
-- per-species layer, and the native preset class used to construct per-sensor
-- preset objects.
config.sensorSensePath = "/Script/Pal.PalAISensorComponent:SelectResponseBySenses"
config.nativePresetClassPath = "/Script/Pal.PalAIResponsePreset"

local PRESET_DIR = "/Game/Pal/Blueprint/Controller/AIResponsePreset/"

config.presetNames = {
    "BP_AIResponsePreset_Default",
    "BP_AIResponsePreset_escape",
    "BP_AIResponsePreset_Escape_to_Battle",
    "BP_AIResponsePreset_friendly",
    "BP_AIResponsePreset_Kill_All",
    "BP_AIResponsePreset_NotInterested",
    "BP_AIResponsePreset_VillageNPC",
    "BP_AIResponsePreset_Warlike",
    "BP_AIResponsePreset_Warlike_Anyway",
    "BP_AIResponsePreset_Warlike_WithoutPlayer",
    "BP_AIResponsePreset_Boss",
}

-- The player-facing grouping of the eleven presets: every preset belongs to exactly one
-- settings key, so the seven kind-of-character settings cover the whole set.
config.presetGroups = {
    alphaAndBossProfile = {
        "BP_AIResponsePreset_Boss",
    },
    aggressivePalProfile = {
        "BP_AIResponsePreset_Warlike",
        "BP_AIResponsePreset_Warlike_Anyway",
        "BP_AIResponsePreset_Warlike_WithoutPlayer",
    },
    skittishPalProfile = {
        "BP_AIResponsePreset_escape",
        "BP_AIResponsePreset_Escape_to_Battle",
    },
    neutralPalProfile = {
        "BP_AIResponsePreset_NotInterested",
        "BP_AIResponsePreset_Default",
    },
    friendlyPalProfile = {
        "BP_AIResponsePreset_friendly",
    },
    villagerProfile = {
        "BP_AIResponsePreset_VillageNPC",
    },
    hostileHumanProfile = {
        "BP_AIResponsePreset_Kill_All",
    },
}

function config.presetDefaultPath(name)
    return PRESET_DIR .. name .. ".Default__" .. name .. "_C"
end

function config.presetClassPath(name)
    return PRESET_DIR .. name .. "." .. name .. "_C"
end

return config
