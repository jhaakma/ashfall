
local activatorConfig = require("mer.ashfall.config.activatorConfig")
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
 
    references = nil,
    requirements = nil
}

this.controllers = {
    campfire = ReferenceController:new{
        requirements = function(self, ref)
            return (
                ref.object and
                ref.object.id and
                activatorConfig.list.campfire:isActivator(ref.object.id)
            )
        end
    },

    fuelConsumer = ReferenceController:new{
        requirements = function(self, ref)
            return ref.data and ref.data.fuelLevel
        end
    },

    griller = ReferenceController:new{
        requirements = function(self, ref)
            return  ref.data and ref.data.hasGrill
        end
    },

    boiler = ReferenceController:new{
        requirements = function(self, ref)
            return (
                ref.data and
                ref.data.utensil
        )
        end
    },

    stewer = ReferenceController:new{
        requirements = function(self, ref)
            return ref.data and ref.data.utensil == "cookingPot"
        end
    },

    brewer = ReferenceController:new{
        requirements = function(self, ref)
           return ref.data and ref.data.utensil == "kettle"
        end
    },

    stewBuffedActor = ReferenceController:new{
        requirements = function(self, ref)
            return ref.data and ref.data.stewBuffTimeLeft
        end
    },

    teaBuffedActor = ReferenceController:new{
        requirements = function(self, ref)
            return ref.data and ref.data.teaBuffTimeLeft
        end
    },
}

local function onRefPlaced(e)
    for controllerName, controller in pairs(this.controllers) do
        if controller:requirements(e.reference) then
            controller:addReference(e.reference)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefPlaced)
event.register("Ashfall:registerReference", onRefPlaced)


local function onObjectInvalidated(e)
    
    local ref = e.object
    for controllerName, controller in pairs(this.controllers) do
        if controller.references[ref] == true then
            controller:removeReference(ref)
        end
    end
end

event.register("objectInvalidated", onObjectInvalidated)

return this