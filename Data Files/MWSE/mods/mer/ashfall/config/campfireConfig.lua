local attachType = {
    dynamic = "dynamic",--Can add or remove
    static = "static", --Can not remove
    none = "none" --Can not add
}

local fireType = {
    lit = "lit",
    unlit = "unlit",
    random = "random"
}

local config =  {
    ["ashfall_campfire"] = {
        campfire = attachType.dynamic,
        supports = attachType.dynamic,
        cookingPot = attachType.dynamic,
        kettle = attachType.dynamic,
        grill = attachType.dynamic,

    },
    ["ashfall_campfire_static"] = {
        campfire = attachType.static,
        supports = attachType.dynamic,
        cookingPot = attachType.dynamic,
        kettle = attachType.dynamic,
        grill = attachType.dynamic,
    },
    ["ashfall_campfire_sup"] = {
        campfire = attachType.static,
        supports = attachType.static,
        cookingPot = attachType.static,
        kettle = attachType.dynamic,
        grill = attachType.none,
    },
    ["ashfall_campfire_grill"] = {
        campfire = attachType.static,
        supports = attachType.dynamic,
        cookingPot = attachType.dynamic,
        kettle = attachType.dynamic,
        grill = attachType.static,
    },
}

local this = {}

function this.getConfig(id)
    local thisConfig = config[id:lower()]
    if thisConfig then return table.copy(thisConfig) end
end

return this