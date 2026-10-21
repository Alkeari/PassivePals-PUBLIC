local config = require("config")
local livecfg = require("livecfg")

-- Quoted in every bug report, so it has to be the version that shipped: the offline suite
-- fails when this and Info.json disagree.
local MOD_VERSION = "1.5.0"

local VERBOSITY = { quiet = 1, normal = 2, verbose = 3 }
local LINE_LEVEL = { warn = 1, normal = 2, verbose = 3 }
local verbosity = VERBOSITY.normal

-- A "warn" line is anything the player needs regardless of the logging setting: a rejected
-- value, a disabled layer, a give-up.
local function log(msg, level)
    if (LINE_LEVEL[level] or LINE_LEVEL.normal) <= verbosity then
        print(string.format("[PassivePals] %s\n", msg))
    end
end

local SLOTS = {
    { name = "SeePlayer", prop = "Discover_Player" },
    { name = "SeeStronger", prop = "Discover_Greater" },
    { name = "SeeEqual", prop = "Discover_Equal" },
    { name = "SeeWeaker", prop = "Discover_Smaller" },
    { name = "AttackedByPlayer", prop = "Damaged_Player" },
    { name = "AttackedByStronger", prop = "Damaged_Greater" },
    { name = "AttackedByEqual", prop = "Damaged_Equal" },
    { name = "AttackedByWeaker", prop = "Damaged_Smaller" },
}

local REACTION = {
    ignore = config.response.Ignore,
    flee = config.response.Escape,
    fight_if_winnable = config.response.Battle,
    fight_always = config.response.Battle_Anyway,
    special = config.response.Special,
    Ignore = config.response.Ignore,
    Escape = config.response.Escape,
    Battle = config.response.Battle,
    Special = config.response.Special,
    Battle_Anyway = config.response.Battle_Anyway,
}

local BUILTIN_PROFILES = {
    vanilla = {},
    pacifist_avenger = {
        SeePlayer = "ignore", SeeStronger = "ignore", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "fight_always", AttackedByStronger = "fight_always",
        AttackedByEqual = "fight_always", AttackedByWeaker = "fight_always",
    },
    realist = {
        SeePlayer = "ignore", SeeStronger = "ignore", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "fight_if_winnable", AttackedByStronger = "fight_if_winnable",
        AttackedByEqual = "fight_if_winnable", AttackedByWeaker = "fight_if_winnable",
    },
    true_pacifist = {
        SeePlayer = "ignore", SeeStronger = "ignore", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "flee", AttackedByStronger = "flee",
        AttackedByEqual = "flee", AttackedByWeaker = "flee",
    },
    punching_bag = {
        SeePlayer = "ignore", SeeStronger = "ignore", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "ignore", AttackedByStronger = "ignore",
        AttackedByEqual = "ignore", AttackedByWeaker = "ignore",
    },
    skittish_avenger = {
        SeePlayer = "flee", SeeStronger = "flee", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "fight_always", AttackedByStronger = "fight_always",
        AttackedByEqual = "fight_always", AttackedByWeaker = "fight_always",
    },
    coward = {
        SeePlayer = "flee", SeeStronger = "flee", SeeEqual = "flee", SeeWeaker = "flee",
        AttackedByPlayer = "flee", AttackedByStronger = "flee",
        AttackedByEqual = "flee", AttackedByWeaker = "flee",
    },
    bloodthirsty = {
        SeePlayer = "fight_always", SeeStronger = "fight_always",
        SeeEqual = "fight_always", SeeWeaker = "fight_always",
        AttackedByPlayer = "fight_always", AttackedByStronger = "fight_always",
        AttackedByEqual = "fight_always", AttackedByWeaker = "fight_always",
    },
    smart_defender = {
        SeePlayer = "ignore", SeeStronger = "ignore", SeeEqual = "ignore", SeeWeaker = "ignore",
        AttackedByPlayer = "fight_if_winnable", AttackedByStronger = "flee",
        AttackedByEqual = "fight_always", AttackedByWeaker = "fight_always",
    },
}

local humanPreset = {}
for _, name in ipairs(config.humanPresetNames) do
    humanPreset[name] = true
end

local knownPreset = {}
for _, name in ipairs(config.presetNames) do
    knownPreset[name] = true
end

local slotByName = {}
for _, slot in ipairs(SLOTS) do
    slotByName[slot.name] = slot
end

-- SpeciesReference.tsv (shipped beside this script) lets bySpecies keys be a
-- Blueprint name, a bare internal row id, or an English display name. SpeciesNames.tsv adds every
-- OTHER name the game ships for the same pals, taken from its own name tables in all seventeen
-- languages, so a player who plays in Korean can write the Korean name and one who plays in
-- Japanese can write the Japanese one. Every language is accepted at once rather than only the
-- one the game is set to: a name is unambiguous either way, and it costs nothing to accept more.
-- English keeps working exactly as before.
local speciesByRowId = {}
local speciesByDisplay = {}
local knownBpName = {}
local predatorBpNames = {}

local function scriptDir()
    return debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[\\/])") or ".\\"
end

-- Both files are tab separated with a header row. Reading a CRLF file on a platform that does
-- not translate line endings leaves the carriage return on the last field, so it goes first.
local function eachRow(fileName, handle)
    local f = io.open(scriptDir() .. fileName, "r")
    if f == nil then
        return
    end
    local first = true
    for line in f:lines() do
        if first then
            first = false
        else
            local fields = {}
            for field in (line:gsub("[\r\n]+$", "") .. "\t"):gmatch("([^\t]*)\t") do
                fields[#fields + 1] = field
            end
            handle(fields)
        end
    end
    f:close()
end

-- A row's Blueprint is its BPClass, not its row id: 33 of the 753 rows differ, among them the
-- raid bosses and the quest-scripted duplicates, and a key naming one of those used to resolve
-- to a Blueprint the game does not have.
pcall(function()
    eachRow("SpeciesReference.tsv", function(fields)
        local rowId, display, bpClass = fields[1], fields[2], fields[5]
        if rowId ~= nil and rowId ~= "" then
            local bpName = "BP_" .. ((bpClass ~= nil and bpClass ~= "") and bpClass or rowId)
            speciesByRowId[rowId] = bpName
            knownBpName[bpName] = true
            if rowId:find("^PREDATOR_") then
                predatorBpNames[#predatorBpNames + 1] = bpName
            end
            if display ~= nil and display ~= "" and not display:find("%(variant%)") then
                speciesByDisplay[display:lower()] = bpName
            end
        end
    end)
end)

-- The same lookup table, filled from the localized names. Read after the English pass so an
-- English spelling always wins a collision.
pcall(function()
    eachRow("SpeciesNames.tsv", function(fields)
        local display, rowId = fields[1], fields[2]
        if display ~= nil and display ~= "" and rowId ~= nil and speciesByRowId[rowId] ~= nil then
            local key = display:lower()
            if speciesByDisplay[key] == nil then
                speciesByDisplay[key] = speciesByRowId[rowId]
            end
        end
    end)
end)

local function normalizeSpeciesKey(key)
    if key:sub(1, 3) == "BP_" then
        return key
    end
    if speciesByRowId[key] then
        return speciesByRowId[key]
    end
    local byDisplay = speciesByDisplay[key:lower()]
    if byDisplay then
        return byDisplay
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Settings: read from the file, validated into one plan table that every layer
-- below reads. Rebuilding it is pure Lua, so it is safe off the game thread.
-- ---------------------------------------------------------------------------

local SETTINGS_FILE = "settings.lua"
local settingsPath = livecfg.resolve(SETTINGS_FILE)

local function loadSettingsFile()
    local text, readErr = livecfg.read(settingsPath)
    if text ~= nil then
        local parsed, parseErr = livecfg.parse(text, settingsPath)
        if parsed ~= nil then
            return parsed, text
        end
        log("settings.lua could not be read (" .. tostring(parseErr) .. "); using defaults", "warn")
        return {}, text
    end
    -- The file did not open beside this script; the package path may still find it.
    local ok, required = pcall(require, SETTINGS_FILE:gsub("%.lua$", ""))
    if ok and type(required) == "table" then
        return required, nil
    end
    log("settings.lua missing or unreadable (" .. tostring(readErr) .. "); using defaults", "warn")
    return {}, nil
end

local function readBoolean(value, context, fallback)
    if value == nil then
        return fallback
    end
    if type(value) == "boolean" then
        return value
    end
    log(string.format("%s must be true or false; using %s", context, tostring(fallback)), "warn")
    return fallback
end

local function readNumber(value, context, fallback, low, high)
    if value == nil then
        return fallback
    end
    local number = tonumber(value)
    if number == nil then
        log(string.format("%s must be a number; using %d", context, fallback), "warn")
        return fallback
    end
    number = math.floor(number)
    if number < low or number > high then
        local clamped = math.max(low, math.min(high, number))
        log(string.format("%s must be between %d and %d; using %d", context, low, high, clamped), "warn")
        return clamped
    end
    return number
end

local LEVEL_DIFFERENCE = { profile = true, respect = true, ignore = true }

local function readChoice(value, context, fallback, allowed)
    if value == nil then
        return fallback
    end
    if type(value) == "string" and allowed[value] then
        return value
    end
    log(string.format("%s names an unknown value %s; using %s", context, tostring(value), fallback), "warn")
    return fallback
end

local function resolveProfile(profiles, value, context, fallback)
    if value == nil then
        return fallback
    end
    if type(value) == "string" and profiles[value] then
        return value
    end
    log(string.format("%s names unknown profile %s; using %s", context, tostring(value), fallback), "warn")
    return fallback
end

local function buildProfiles(user)
    local profiles = {}
    for name, def in pairs(BUILTIN_PROFILES) do
        profiles[name] = def
    end
    if type(user.behaviorProfiles) == "table" then
        for name, def in pairs(user.behaviorProfiles) do
            if type(name) ~= "string" or type(def) ~= "table" then
                log("behaviorProfiles entry ignored (name must be a string, value a table): " .. tostring(name), "warn")
            else
                local clean = {}
                local valid = true
                for slotName, reaction in pairs(def) do
                    if slotByName[slotName] == nil then
                        log(string.format("profile %s ignored: unknown slot %s", name, tostring(slotName)), "warn")
                        valid = false
                    elseif reaction ~= "vanilla" and REACTION[reaction] == nil then
                        log(string.format("profile %s ignored: unknown reaction %s in slot %s", name, tostring(reaction), tostring(slotName)), "warn")
                        valid = false
                    else
                        clean[slotName] = reaction
                    end
                end
                if valid then
                    profiles[name] = clean
                end
            end
        end
    elseif user.behaviorProfiles ~= nil then
        log("behaviorProfiles must be a table; ignored", "warn")
    end
    return profiles
end

local function buildState(user)
    local s = {}

    -- Logging first, so every warning below obeys the level the file asks for.
    verbosity = VERBOSITY.normal
    if user.logging ~= nil then
        if type(user.logging) == "string" and VERBOSITY[user.logging] ~= nil then
            verbosity = VERBOSITY[user.logging]
        else
            log("logging names an unknown level " .. tostring(user.logging) .. "; using normal", "warn")
        end
    end
    s.logging = verbosity

    s.preservePetting = readBoolean(user.preservePettingBehavior, "preservePettingBehavior", true)
    s.levelDifference = readChoice(user.levelDifference, "levelDifference", "profile", LEVEL_DIFFERENCE)
    s.pollSeconds = readNumber(user.pollSeconds, "pollSeconds", 5, 1, 60)
    s.pollLimit = readNumber(user.pollLimit, "pollLimit", 120, 10, 600)
    s.liveReloadSeconds = readNumber(user.liveReloadSeconds, "liveReloadSeconds", 2, 0, 60)

    s.profiles = buildProfiles(user)

    s.defaultPalProfile = resolveProfile(s.profiles, user.defaultPalProfile, "defaultPalProfile", "pacifist_avenger")
    s.defaultHumanProfile = resolveProfile(s.profiles, user.defaultHumanProfile, "defaultHumanProfile", "vanilla")

    -- The seven kind-of-character settings, each covering one group of presets. "default"
    -- (and a missing value) means "fall through to the pal or human default".
    s.groupProfile = {}
    s.groupCount = 0
    for settingName, presetNames in pairs(config.presetGroups) do
        local value = user[settingName]
        if value ~= nil and value ~= "default" then
            local resolved = nil
            if type(value) == "string" and s.profiles[value] then
                resolved = value
            else
                log(string.format("%s names unknown profile %s; using the default for those characters",
                    settingName, tostring(value)), "warn")
            end
            if resolved ~= nil then
                for _, presetName in ipairs(presetNames) do
                    s.groupProfile[presetName] = resolved
                end
                s.groupCount = s.groupCount + 1
            end
        end
    end

    s.byAIPreset = {}
    s.presetCount = 0
    if type(user.byAIPreset) == "table" then
        for presetName, profileName in pairs(user.byAIPreset) do
            if not knownPreset[presetName] then
                log("byAIPreset entry ignored, unknown preset: " .. tostring(presetName), "warn")
            else
                s.byAIPreset[presetName] = resolveProfile(s.profiles, profileName, "byAIPreset." .. presetName,
                    humanPreset[presetName] and s.defaultHumanProfile or s.defaultPalProfile)
                s.presetCount = s.presetCount + 1
            end
        end
    elseif user.byAIPreset ~= nil then
        log("byAIPreset must be a table; ignored", "warn")
    end

    s.bySpecies = {}
    s.speciesCount = 0

    local function addSpecies(speciesName, profileName, context)
        if type(speciesName) ~= "string" then
            log(context .. " key ignored (must be a string): " .. tostring(speciesName), "warn")
            return
        end
        local bpName = normalizeSpeciesKey(speciesName)
        if bpName == nil then
            log(context .. " key ignored, not a known Blueprint name, row id, or display name: "
                .. speciesName, "warn")
            return
        end
        if bpName ~= speciesName then
            log(string.format("%s: %s resolved to %s", context, speciesName, bpName), "verbose")
        elseif not knownBpName[bpName] then
            log(string.format("%s names %s, which is not in the shipped species reference; it does nothing unless the game really has that Blueprint",
                context, speciesName), "warn")
        end
        if s.bySpecies[bpName] == nil then
            s.speciesCount = s.speciesCount + 1
        end
        s.bySpecies[bpName] = resolveProfile(s.profiles, profileName, context .. "." .. speciesName, "vanilla")
    end

    -- Rampaging predators, the red-aura pals, share the Boss preset with every alpha but each has
    -- its own Blueprint (the PREDATOR_ rows of the species reference), so their setting is carried
    -- by the species layer. A speciesRules or bySpecies entry naming one is applied after and wins.
    local predatorValue = user.rampagingPredatorProfile
    if predatorValue ~= nil and predatorValue ~= "default" then
        if type(predatorValue) == "string" and s.profiles[predatorValue] then
            for _, bpName in ipairs(predatorBpNames) do
                if s.bySpecies[bpName] == nil then
                    s.speciesCount = s.speciesCount + 1
                end
                s.bySpecies[bpName] = predatorValue
            end
            s.groupCount = s.groupCount + 1
        else
            log(string.format("rampagingPredatorProfile names unknown profile %s; using the default for those characters",
                tostring(predatorValue)), "warn")
        end
    end

    -- The three fill-in slots, so a species rule can be set from a settings screen without
    -- editing this file. A bySpecies entry for the same species is applied after and wins.
    if type(user.speciesRules) == "table" then
        for _, slot in ipairs({ "rule1", "rule2", "rule3" }) do
            local speciesName = user.speciesRules[slot .. "Species"]
            if type(speciesName) == "string" and speciesName:match("%S") ~= nil then
                addSpecies(speciesName, user.speciesRules[slot .. "Profile"], "speciesRules." .. slot)
            end
        end
    elseif user.speciesRules ~= nil then
        log("speciesRules must be a table; ignored", "warn")
    end

    if type(user.bySpecies) == "table" then
        for speciesName, profileName in pairs(user.bySpecies) do
            addSpecies(speciesName, profileName, "bySpecies")
        end
    elseif user.bySpecies ~= nil then
        log("bySpecies must be a table; ignored", "warn")
    end

    s.presetPlan = {}
    for _, name in ipairs(config.presetNames) do
        local profileName = s.byAIPreset[name] or s.groupProfile[name]
        if profileName == nil then
            profileName = humanPreset[name] and s.defaultHumanProfile or s.defaultPalProfile
        end
        s.presetPlan[name] = profileName
    end

    return s
end

local state = buildState({})

local function planSummary(s)
    return string.format("pals=%s humans=%s petting=%s levelDifference=%s groupOverrides=%d presetOverrides=%d speciesOverrides=%d",
        s.defaultPalProfile, s.defaultHumanProfile, s.preservePetting and "preserved" or "overwritten",
        s.levelDifference, s.groupCount, s.presetCount, s.speciesCount)
end

local function logPlan(s)
    log("plan: " .. planSummary(s))
    for _, name in ipairs(config.presetNames) do
        if s.presetPlan[name] ~= "vanilla" then
            log("  " .. name .. " -> " .. s.presetPlan[name])
        end
    end
end

local function sameMap(a, b)
    for key, value in pairs(a) do
        if b[key] ~= value then
            return false
        end
    end
    for key, value in pairs(b) do
        if a[key] ~= value then
            return false
        end
    end
    return true
end

local function sameProfiles(a, b)
    for name, def in pairs(a) do
        if b[name] == nil or not sameMap(def, b[name]) then
            return false
        end
    end
    for name in pairs(b) do
        if a[name] == nil then
            return false
        end
    end
    return true
end

local function describeChanges(old, new)
    local parts = {}
    if old.defaultPalProfile ~= new.defaultPalProfile then parts[#parts + 1] = "pal default" end
    if old.defaultHumanProfile ~= new.defaultHumanProfile then parts[#parts + 1] = "human default" end
    if old.preservePetting ~= new.preservePetting then parts[#parts + 1] = "petting" end
    if old.levelDifference ~= new.levelDifference then parts[#parts + 1] = "level difference" end
    if not sameMap(old.groupProfile, new.groupProfile) then parts[#parts + 1] = "kinds of character" end
    if not sameMap(old.byAIPreset, new.byAIPreset) then parts[#parts + 1] = "AI presets" end
    if not sameMap(old.bySpecies, new.bySpecies) then parts[#parts + 1] = "species" end
    if not sameProfiles(old.profiles, new.profiles) then parts[#parts + 1] = "profiles" end
    if old.logging ~= new.logging then parts[#parts + 1] = "logging" end
    if old.liveReloadSeconds ~= new.liveReloadSeconds then parts[#parts + 1] = "reload interval" end
    if old.pollSeconds ~= new.pollSeconds or old.pollLimit ~= new.pollLimit then parts[#parts + 1] = "poll timing" end
    if #parts == 0 then
        return "nothing that changes behavior"
    end
    return table.concat(parts, ", ")
end

-- ---------------------------------------------------------------------------
-- Engine access.
-- ---------------------------------------------------------------------------

local responseName = {}
for name, value in pairs(config.response) do
    responseName[value] = name
end

local function valueLabel(v)
    local n = responseName[tonumber(v) or -1]
    if n then
        return string.format("%s(%d)", n, tonumber(v))
    end
    return tostring(v)
end

local function findPreset(name)
    local obj = StaticFindObject(config.presetDefaultPath(name))
    if obj and obj:IsValid() then
        return obj
    end
    local cls = StaticFindObject(config.presetClassPath(name))
    if cls and cls:IsValid() then
        local ok, cdo = pcall(function() return cls:GetCDO() end)
        if ok and cdo and cdo:IsValid() then
            return cdo
        end
    end
    return nil
end

-- Vanilla values are snapshotted before any write so the per-species layer can
-- rebuild true vanilla behavior even after the shared preset was overridden.
local vanillaValues = {}

-- False when the build no longer carries all eight slots. Nothing is written to a preset that
-- could not be snapshotted: a half-written preset has no vanilla values left to go back to.
local function snapshotVanilla(preset, presetName)
    if vanillaValues[presetName] then
        return true
    end
    local snap = {}
    for _, slot in ipairs(SLOTS) do
        local v = preset[slot.prop]
        if v == nil then
            return false
        end
        snap[slot.prop] = tonumber(v)
    end
    vanillaValues[presetName] = snap
    return true
end

-- Every apply starts from the snapshotted vanilla values, so a rule dropped from the
-- settings file reverts instead of sticking until the next launch.
local function restoreVanilla(preset, presetName)
    local snap = vanillaValues[presetName]
    if snap == nil then
        return
    end
    for _, slot in ipairs(SLOTS) do
        local want = snap[slot.prop]
        if want ~= nil and tonumber(preset[slot.prop]) ~= want then
            preset[slot.prop] = want
        end
    end
end

-- The engine gates a plain Battle verdict on relative strength and lets Battle_Anyway through
-- ungated, so the difference between "fight" and "fight only if it can win" is which of the two
-- a slot holds. levelDifference rewrites that one axis across whatever profile was assigned,
-- which is what lets a player keep the game's own strength check without giving up their profile.
local function reactionValue(reaction)
    local value = REACTION[reaction]
    if state.levelDifference == "respect" and value == config.response.Battle_Anyway then
        return config.response.Battle
    elseif state.levelDifference == "ignore" and value == config.response.Battle then
        return config.response.Battle_Anyway
    end
    return value
end

local function applyProfileToObject(target, profileDef, label)
    local changes = {}
    for _, slot in ipairs(SLOTS) do
        local reaction = profileDef[slot.name]
        if reaction ~= nil and reaction ~= "vanilla" then
            local targetValue = reactionValue(reaction)
            local current = target[slot.prop]
            if current == nil then
                return false, "property missing: " .. slot.prop
            end
            local currentNum = tonumber(current)
            if state.preservePetting and currentNum == config.response.Special
                and targetValue ~= config.response.Special then
                changes[#changes + 1] = slot.prop .. " kept " .. valueLabel(currentNum) .. " (petting preserved)"
            elseif currentNum ~= targetValue then
                target[slot.prop] = targetValue
                changes[#changes + 1] = string.format("%s %s->%s", slot.prop, valueLabel(currentNum), valueLabel(targetValue))
            end
        end
    end
    if #changes == 0 then
        log(label .. ": already compliant, nothing changed", "verbose")
    else
        log(label .. ": " .. table.concat(changes, ", "))
    end
    return true, nil
end

-- ---------------------------------------------------------------------------
-- Preset layer: rewrite the shared preset objects.
-- ---------------------------------------------------------------------------

local applied = {}
local failed = {}
local pollCount = 0
local finished = false
local loopRunning = false

local function presetWorkExists()
    for _, name in ipairs(config.presetNames) do
        if state.presetPlan[name] ~= "vanilla" then
            return true
        end
    end
    return false
end

local function tryApplyAll()
    local remaining = 0
    for _, name in ipairs(config.presetNames) do
        if not applied[name] and not failed[name] then
            local preset = findPreset(name)
            if preset == nil then
                remaining = remaining + 1
            elseif not snapshotVanilla(preset, name) then
                failed[name] = true
                log("DISABLED for " .. name .. ": it no longer carries all eight reaction slots. The game build no longer matches; wait for a mod update.", "warn")
            else
                restoreVanilla(preset, name)
                if state.presetPlan[name] == "vanilla" then
                    applied[name] = true
                else
                    local ok, applyOk, applyErr = pcall(applyProfileToObject, preset, state.profiles[state.presetPlan[name]], name)
                    if ok and applyOk then
                        applied[name] = true
                    elseif ok then
                        failed[name] = true
                        log("DISABLED for " .. name .. ": " .. tostring(applyErr) .. ". The game build no longer matches; wait for a mod update.", "warn")
                    else
                        failed[name] = true
                        log("DISABLED for " .. name .. ": unexpected error: " .. tostring(applyOk), "warn")
                    end
                end
            end
        end
    end
    return remaining
end

local function startPresetLoop()
    if loopRunning then
        return
    end
    pollCount = 0
    finished = false
    loopRunning = true
    local started = pcall(LoopAsync, state.pollSeconds * 1000, function()
        pollCount = pollCount + 1
        ExecuteInGameThread(function()
            local ok, remaining = pcall(tryApplyAll)
            if not ok then
                return
            end
            if remaining == 0 then
                local appliedCount = 0
                for _ in pairs(applied) do
                    appliedCount = appliedCount + 1
                end
                if appliedCount == 0 then
                    log("DISABLED: no AI response preset could be found on this game build; the mod is inactive. Wait for a mod update.", "warn")
                else
                    log(string.format("preset layer done: %d preset(s) processed; going idle", appliedCount))
                end
                finished = true
            end
        end)
        if pollCount >= state.pollLimit then
            log("poll limit reached; presets never loaded this session. The mod is inactive until the settings file changes or the game restarts.", "warn")
            loopRunning = false
            return true
        end
        if finished then
            loopRunning = false
            return true
        end
        return false
    end)
    if not started then
        loopRunning = false
        log("could not start the preset poll loop; the preset layer is inactive this session.", "warn")
    end
end

-- ---------------------------------------------------------------------------
-- Species layer: per-sensor preset objects assigned when a configured species
-- first runs a sense decision. Uses the verified script-VM sense hook.
-- ---------------------------------------------------------------------------

local speciesArmed = false
local speciesLayerBroken = false
local seenSensors = {}
local speciesApplied = {}

local function buildSpeciesPreset(sensor, currentPreset, speciesName, profileName)
    local nativeClass = StaticFindObject(config.nativePresetClassPath)
    if nativeClass == nil or not nativeClass:IsValid() then
        return nil, "native preset class not found"
    end
    local fresh = StaticConstructObject(nativeClass, sensor)
    if fresh == nil or not fresh:IsValid() then
        return nil, "StaticConstructObject returned nothing"
    end
    local currentClassName = nil
    pcall(function()
        currentClassName = currentPreset:GetClass():GetFullName():match("([A-Za-z0-9_]+)_C$")
    end)
    local base = currentClassName and vanillaValues[currentClassName] or nil
    for _, slot in ipairs(SLOTS) do
        local baseValue = base and base[slot.prop] or tonumber(currentPreset[slot.prop])
        if baseValue == nil then
            return nil, "could not read " .. slot.prop
        end
        fresh[slot.prop] = baseValue
    end
    local ok, applyOk, applyErr = pcall(applyProfileToObject, fresh, state.profiles[profileName],
        speciesName .. " (per-species, from " .. tostring(currentClassName) .. " vanilla)")
    if not ok or not applyOk then
        return nil, tostring(applyErr or applyOk)
    end
    return fresh, nil
end

local function onSenseDecision(Context)
    if speciesLayerBroken or state.speciesCount == 0 then
        return
    end
    pcall(function()
        local sensor = Context:get()
        local sensorKey = sensor:GetFullName()
        if seenSensors[sensorKey] then
            return
        end
        local owner = sensor:GetOuter()
        if owner == nil or not owner:IsValid() then
            return
        end
        local pawn = owner.Pawn
        if pawn == nil or not pawn:IsValid() then
            return
        end
        local speciesName = pawn:GetClass():GetFullName():match("([A-Za-z0-9_]+)_C$")
        if speciesName == nil then
            return
        end
        -- Marked only once the species is known. A sensor that senses before its pawn is
        -- attached would otherwise be written off for the rest of the session.
        seenSensors[sensorKey] = true
        if state.bySpecies[speciesName] == nil then
            return
        end
        local profileName = state.bySpecies[speciesName]
        local currentPreset = sensor.AIResponsePreset
        if currentPreset == nil or not currentPreset:IsValid() then
            return
        end
        local fresh, buildErr = buildSpeciesPreset(sensor, currentPreset, speciesName, profileName)
        if fresh == nil then
            speciesLayerBroken = true
            log("species layer DISABLED: " .. tostring(buildErr) .. ". Preset-level settings still apply.", "warn")
            return
        end
        sensor.AIResponsePreset = fresh
        speciesApplied[sensorKey] = { sensor = sensor, original = currentPreset }
        log(string.format("species override applied: %s -> %s", speciesName, profileName))
    end)
end

local function armSpeciesLayer()
    if speciesArmed or speciesLayerBroken then
        return
    end
    local ok, err = pcall(function()
        RegisterHook(config.sensorSensePath, onSenseDecision)
    end)
    if ok then
        speciesArmed = true
        log(string.format("species layer armed for %d species", state.speciesCount))
    else
        speciesLayerBroken = true
        log("species layer DISABLED: sense hook failed: " .. tostring(err) .. ". Preset-level settings still apply.", "warn")
    end
end

-- A species rule that a live edit changed or dropped has to come off the sensors it already
-- reached; the shared preset it goes back to is what the preset layer governs. Each sensor
-- decides again the next time it senses.
local function revertSpeciesOverrides()
    for key, entry in pairs(speciesApplied) do
        pcall(function()
            if entry.sensor:IsValid() and entry.original:IsValid() then
                entry.sensor.AIResponsePreset = entry.original
            end
        end)
        speciesApplied[key] = nil
    end
    seenSensors = {}
end

-- ---------------------------------------------------------------------------
-- Live settings: re-run both layers over the plan now in force.
-- ---------------------------------------------------------------------------

local function applyLive()
    applied = {}
    failed = {}
    local loopWasRunning = loopRunning
    local ok = pcall(ExecuteInGameThread, function()
        pcall(revertSpeciesOverrides)
        if not loopWasRunning then
            local applyOk, remaining = pcall(tryApplyAll)
            if not applyOk then
                log("re-applying the presets failed: " .. tostring(remaining), "warn")
                startPresetLoop()
            elseif remaining > 0 then
                startPresetLoop()
            end
        end
        if state.speciesCount > 0 then
            armSpeciesLayer()
        end
    end)
    if not ok then
        log("the edited settings could not reach the game this session; they apply on the next launch.", "warn")
    end
end

-- Runs off the game thread, in the watcher's loop: rebuilding the plan is pure Lua, and
-- every engine write below it goes through applyLive's ExecuteInGameThread.
local function onSettingsChanged(user)
    local previous = state
    state = buildState(user)
    log("settings reloaded: " .. describeChanges(previous, state) .. "; " .. planSummary(state), "warn")
    applyLive()
end

-- ---------------------------------------------------------------------------
-- Boot.
-- ---------------------------------------------------------------------------

local bootUser, bootText = loadSettingsFile()
state = buildState(bootUser)

log("Passive Pals v" .. MOD_VERSION .. " loaded", "warn")
logPlan(state)

if presetWorkExists() or state.speciesCount > 0 then
    startPresetLoop()
else
    log("everything set to vanilla; nothing to change until settings.lua says otherwise")
end

if state.speciesCount > 0 then
    armSpeciesLayer()
end

local watcher = livecfg.new({
    path = settingsPath,
    initialText = bootText,
    onChange = onSettingsChanged,
    onError = function(message) log(message, "warn") end,
})

if state.liveReloadSeconds <= 0 then
    log("live settings reload is off (liveReloadSeconds = 0); edits apply on the next launch")
elseif livecfg.run(watcher, function() return state.liveReloadSeconds end) then
    log(string.format("watching settings.lua; an edit applies within %d second(s)", state.liveReloadSeconds))
else
    log("live settings reload could not start; edits apply on the next launch", "warn")
end
