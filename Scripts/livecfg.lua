-- Watches a settings file and reports an edit while the game runs.
--
-- It re-reads the file text rather than require()ing it: require caches its result in
-- package.loaded, so every later require would hand back the table read at boot.
--
-- Nothing here touches a UObject. The watch loop runs off the game thread (LoopAsync),
-- where file reading and parsing are safe; a caller that needs the engine hops to the game
-- thread itself from the change callback.

local LiveCfg = {}

local function scriptDir()
    local source = debug.getinfo(1, "S").source:gsub("^@", "")
    return source:match("^(.*[\\/])") or ".\\"
end

function LiveCfg.resolve(fileName)
    return scriptDir() .. fileName
end

function LiveCfg.read(path)
    local file, openErr = io.open(path, "rb")
    if file == nil then
        return nil, tostring(openErr or "could not be opened")
    end
    local ok, text = pcall(function() return file:read("*a") end)
    pcall(function() file:close() end)
    if not ok or type(text) ~= "string" then
        return nil, "could not be read"
    end
    return text
end

-- The chunk runs in an empty environment: a settings file is pure data, so nothing in it
-- needs to reach the game, this mod, or the rest of Lua.
function LiveCfg.parse(text, chunkName)
    local chunk, syntaxErr = load(text, "@" .. tostring(chunkName), "t", {})
    if chunk == nil then
        return nil, tostring(syntaxErr)
    end
    -- load's env argument is the 5.2 way and setfenv is the 5.1 way. Doing both costs nothing
    -- and means the sandbox does not depend on which of the two the host Lua honors.
    if type(setfenv) == "function" then
        pcall(setfenv, chunk, {})
    end
    local ok, result = pcall(chunk)
    if not ok then
        return nil, tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "the file must return a table"
    end
    return result
end

function LiveCfg.new(opts)
    return {
        path = opts.path,
        lastText = opts.initialText,
        failedText = nil,
        onChange = opts.onChange,
        onError = opts.onError,
        unreadableReported = false,
        generation = 0,
    }
end

local function report(watcher, message)
    if watcher.onError ~= nil then
        pcall(watcher.onError, message)
    end
end

-- One read, compare and parse cycle. Returns a status word, which the offline harness
-- asserts on: unchanged, changed, unreadable, rejected, failed.
function LiveCfg.check(watcher)
    local text, readErr = LiveCfg.read(watcher.path)
    if text == nil then
        -- A file caught mid-write reports the same failure every tick; say it once.
        if not watcher.unreadableReported then
            watcher.unreadableReported = true
            report(watcher, "settings.lua " .. tostring(readErr)
                .. "; keeping the settings already in force")
        end
        return "unreadable"
    end
    watcher.unreadableReported = false
    if text == watcher.lastText or text == watcher.failedText then
        return "unchanged"
    end
    local parsed, parseErr = LiveCfg.parse(text, watcher.path)
    if parsed == nil then
        watcher.failedText = text
        report(watcher, "settings.lua could not be read (" .. tostring(parseErr)
            .. "); keeping the settings already in force")
        return "rejected"
    end
    watcher.lastText = text
    watcher.failedText = nil
    if watcher.onChange ~= nil then
        local ok, err = pcall(watcher.onChange, parsed)
        if not ok then
            report(watcher, "applying the edited settings failed (" .. tostring(err)
                .. "); keeping the settings already in force")
            return "failed"
        end
    end
    return "changed"
end

-- One loop for the life of the session, ticking once a second and counting seconds until the
-- configured interval is up, so an edit to the interval itself takes effect at the next tick.
-- Restarting LoopAsync from inside its own callback would do the same job in fewer lines, but
-- nesting it that way is not verified on either UE4SS build.
--
-- Setting the interval to 0 ends the loop. Nothing reads the file after that, which is the whole
-- point of turning it off, and it is also why turning it back on cannot take effect until the
-- next launch: there is no reader left to notice.
local TICK_MS = 1000

function LiveCfg.tick(watcher, intervalSeconds)
    local wanted = tonumber(intervalSeconds()) or 0
    if wanted <= 0 then
        return "off"
    end
    watcher.elapsed = (watcher.elapsed or 0) + TICK_MS / 1000
    if watcher.elapsed < wanted then
        return "waiting"
    end
    watcher.elapsed = 0
    return LiveCfg.check(watcher)
end

function LiveCfg.run(watcher, intervalSeconds)
    watcher.elapsed = 0
    return pcall(LoopAsync, TICK_MS, function()
        local ok, status = pcall(LiveCfg.tick, watcher, intervalSeconds)
        return ok and status == "off"
    end)
end

return LiveCfg
