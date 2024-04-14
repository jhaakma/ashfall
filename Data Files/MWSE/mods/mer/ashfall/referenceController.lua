
local staticConfigs = require('mer.ashfall.config.staticConfigs')
local this = {}

---@class Ashfall.ReferenceController
local ReferenceController = {
    new = function(self, o)
        o = o or {}   -- create object if user does not provide one
        o.references = {}
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    addReference = function(self, ref)
        self.references[ref] = true
    end,

    removeReference = function(self, ref)
            self.references[ref] = nil
    end,

    isReference = function(self, ref)
        return self:requirements(ref)
    end,

    iterate = function(self, callback)
        for ref, _ in pairs(self.references) do
            --check requirements in case it's no longer valid
            if self:requirements(ref) then
                if ref.sceneNode then
                    callback(ref)
                end
            else
                --no longer valid, remove from ref list
                self.references[ref] = nil
            end
        end
    end,

    references = nil,
    requirements = nil
}

this.controllers = {
    campfire = ReferenceController:new{
        requirements = function(_, ref)
            return ref.sceneNode
                and ref.sceneNode:getObjectByName("SWITCH_FIRE")
        end
    },

    weakFire = ReferenceController:new{
        requirements = function(_, ref)
            return ref.sceneNode
                and ref.sceneNode:getObjectByName("SWITCH_CANDLELIGHT")
        end
    },

    fuelConsumer = ReferenceController:new{
        requirements = function(_, ref)
            return ref.supportsLuaData
            and ref.data
            and ref.data.fuelLevel
        end
    },

    -- boiler = ReferenceController:new{
    --     requirements = function(_, ref)
    --         local isboiler = ref.supportsLuaData
    --             and ref.data
    --             and ref.data.waterHeat ~= nil
    --         return isboiler
    --     end
    -- },

    stewer = ReferenceController:new{
        requirements = function(_, ref)
            local isPot = ref.supportsLuaData
                and ref.data
                and ref.data.utensil == "cookingPot"
                or staticConfigs.cookingPots[ref.object.id:lower()]
            return isPot
        end,
    },

    brewer = ReferenceController:new{
        requirements = function(_, ref)
            return ref.supportsLuaData
                and ref.data
                and ref.data.utensil == "kettle"
            or staticConfigs.kettles[ref.object.id:lower()]
        end
    },

    stewBuffedActor = ReferenceController:new{
        requirements = function(_, ref)
            return ref.supportsLuaData
                and ref.data
                and ref.data.stewBuffTimeLeft
        end
    },

    teaBuffedActor = ReferenceController:new{
        requirements = function(_, ref)
            return ref.supportsLuaData
                and ref.data
                and ref.data.teaBuffTimeLeft
        end
    },

    hazard = ReferenceController:new{
        requirements = function(_, ref)
            return staticConfigs.heatSourceValues[ref.object.id:lower()]
        end
    },

    waterContainer = ReferenceController:new{
        requirements = function(_, ref)
            return staticConfigs.bottleList[ref.object.id:lower()]
        end
    },

    utensil = ReferenceController:new{
        requirements = function(_, ref)
            return ref.sceneNode and ref.sceneNode:getObjectByName("POT_WATER")
        end
    },
    kettle = ReferenceController:new{
        requirements = function(_, ref)
            return ref.sceneNode and ref.sceneNode:getObjectByName("SWITCH_KETTLE_STEAM")
        end
    },
    fryingPan = ReferenceController:new{
        requirements = function(_, ref)
            local grillConfig = staticConfigs.grills[ref.object.id:lower()]
            return grillConfig and grillConfig.fryingPan
        end
    },
    grillableFood = ReferenceController:new{
        requirements = function(_, ref)
            return staticConfigs.foodConfig.getGrillValues(ref.object)
        end
    },
    waterFilter = ReferenceController:new{
        requirements = function(_, ref)
            local isWaterFilter = ref.sceneNode
                and ref.sceneNode:getObjectByName("FILTER_WATER")
            return isWaterFilter
        end
    }
}

local function onRefPlaced(e)
    for _, controller in pairs(this.controllers) do
        if controller:requirements(e.reference) then
            controller:addReference(e.reference)
        end
    end
end
event.register(tes3.event.referenceActivated, onRefPlaced)
event.register("Ashfall:registerReference", onRefPlaced)

event.register(tes3.event.loaded, function(e)
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            onRefPlaced{ reference = ref }
        end
    end
end)

local function onObjectInvalidated(e)
    local ref = e.object
    for _, controller in pairs(this.controllers) do
        if controller.references[ref] then
            controller:removeReference(ref)
        end
    end
end
event.register("objectInvalidated", onObjectInvalidated)

---@param e { id: string, requirements: fun(self: Ashfall.ReferenceController, ref: tes3reference): boolean }
function this.registerReferenceController(e)
    assert(e.id, "No id provided")
    assert(e.requirements, "No reference requirements provided")
    assert(this.controllers[e.id] == nil, "Reference controller already registered")
    this.controllers[e.id] =  ReferenceController:new{ requirements = e.requirements }
    return this.controllers[e.id]
end
event.register("Ashfall:RegisterReferenceController", this.registerReferenceController)

function this.iterateReferences(refType, callback)
    for ref, _ in pairs(this.controllers[refType].references) do
        --check requirements in case it's no longer valid
        if this.controllers[refType]:requirements(ref) then
            if ref.sceneNode then
                callback(ref)
            end
        else
            --no longer valid, remove from ref list
            this.controllers[refType].references[ref] = nil
        end
    end
end

---@param refType string
---@param reference tes3reference
---@return boolean
function this.isReference(refType, reference)
    return this.controllers[refType]:isReference(reference)
end

return this