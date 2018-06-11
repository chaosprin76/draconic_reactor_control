local io = require("io")
local s = require("serialization")

local state = {
    settings = nil
}


local settings = {}

local stateControl = {}

stateControl.writeSettings = function()
    local file = io.open("./tmp/settings", "w")
    file:write(s.serialize(state.settings))
    return file:close()
end

stateControl.readSettings = function()
    local file = io.open("./tmp/settings")
    if file then
        state.settings = s.unserialize(file:read("all"))
        
    else
        state.settings = {}
    end
    return file.close() or nil
end

settings.get = function(key)
    if not state.settings then stateControl.readSettings() end
    
    return settings.state or {}
end

settings.set = function(val)
    state.settings = val
    stateControl.writeSettings()
    return state.settings
end

return {
    settings = settings
}