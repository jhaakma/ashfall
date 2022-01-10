
local staticConfigs = require('mer.ashfall.config.staticConfigs')
local this = {}


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
            return ref.data and ref.data.fuelLevel
        end
    },

    boiler = ReferenceController:new{
        requirements = function(_, ref)
            local isboiler = (
                ref.data and
                ref.data.waterHeat ~= nil
            )
            return isboiler
        end
    },

    stewer = ReferenceController:new{
        requirements = function(_, ref)
            return ref.data
                and ref.data.utensil == "cookingPot"
                or staticConfigs.cookingPots[ref.object.id:lower()]
        end
    },

    brewer = ReferenceController:new{
        requirements = function(_, ref)
           return ref.data
            and ref.data.utensil == "kettle"
            or staticConfigs.kettles[ref.object.id:lower()]
        end
    },

    stewBuffedActor = ReferenceController:new{
        requirements = function(_, ref)
            return ref.data and ref.data.stewBuffTimeLeft
        end
    },

    teaBuffedActor = ReferenceController:new{
        requirements = function(_, ref)
            return ref.data and ref.data.teaBuffTimeLeft
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
}

local function onRefPlaced(e)
    for _, controller in pairs(this.controllers) do
        if controller:requirements(e.reference) then
            controller:addReference(e.reference)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefPlaced)
event.register("Ashfall:registerReference", onRefPlaced)


local function onObjectInvalidated(e)
    local ref = e.object
    for _, controller in pairs(this.controllers) do
        if controller.references[ref] == true then
            controller:removeReference(ref)
        end
    end
end
event.register("objectInvalidated", onObjectInvalidated)

function this.registerReferenceController(e)
    assert(e.id, "No id provided")
    assert(e.requirements, "No reference requirements provieded")
    this.controllers[e.id] =  ReferenceController:new{ requirements = e.requirements }
end
event.register("Ashfall:RegisterReferenceController", this.registerReferenceController)

return this