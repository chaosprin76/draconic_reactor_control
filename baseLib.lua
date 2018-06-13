local io = require("io")
local s = require("serialization")


-------------------------------------------------------------------------------
-- # settings-API

local state = {
    settings = nil
}


local settings = {}

local stateControl = {}

stateControl.writeSettings = function()
    local file = io.open("./tmp/settings", "w")
    if file then
        local sets = state.settings or {}
        file:write(s.serialize(sets))
        return file:close()
    else
        return nil
    end
end

stateControl.readSettings = function()
    local file = io.open("./tmp/settings")
    if file then
        state.settings = s.unserialize(file:read("all"))
        return file:close()
    else
        state.settings = {}
        return nil
    end
end

settings.get = function(key)
    if not state.settings then 
        stateControl.readSettings()
    end
    if not key then
        return state.settings
    else
        return state.settings[key]
    end
end

settings.set = function(val)
    for key, v in pairs(val) do
        state.settings[key] = v
    end
    stateControl.writeSettings()
    return state.settings
end

-------------------------------------------------------------------------------
-- # calc (math helper functions)

calc = {}

calc.percentage = function(max, val)
    if max == 0 then
        return 0
    else
        return math.ceil(val / max * 10000) * 0.01
    end
end

return {
    settings = settings,
    calc = calc,
    state = stateControl
}