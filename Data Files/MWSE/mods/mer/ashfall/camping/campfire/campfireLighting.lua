
--[[
    Initialises static campfires as Ashfall campfires,
    with a random chance of having utensils attached, that
    may have water, tea or stew in them.

]]
local common = require ("mer.ashfall.common.common")
local skillConfigs = require("mer.ashfall.config.skillConfigs")
local logger = common.createLogger("campfireLighting")
local ReferenceController = require("mer.ashfall.referenceController")

local function initialiseCampfireSoundAndFlame()
    local function doUpdate(campfire)
        if tes3.player.cell ~= campfire.cell then return end

        if campfire.data.isLit ~= true then
            campfire:deleteDynamicLightAttachment()
        end

        tes3.removeSound{
            sound = "Fire",
            reference = campfire,
        }
        tes3.removeSound{
            sound = "ashfall_boil",
            reference = campfire
        }

        --Add a frame after they have been removed
        timer.delayOneFrame(function()
            local isCampfire = ReferenceController.controllers.campfire:isReference(campfire)
            if isCampfire and campfire.data.isLit then
                if not tes3.getSoundPlaying{ reference = campfire, sound = "Fire" } then
                    logger:debug("initilaliseCampfire: playing sound on %s", campfire.object.id)
                    tes3.playSound{
                        sound = "Fire",
                        reference = campfire,
                    }
                end
            end
            -- local waterAmount = campfire.data.waterAmount or 0
            -- local waterHeat = campfire.data.waterHeat or 0
            -- if waterAmount > 0 and waterHeat >= common.staticConfigs.hotWaterHeatValue then
            --     if not tes3.getSoundPlaying{ reference = campfire, sound = "ashfall_boil" } then
            --         logger:debug("initilaliseCampfire: playing boil sound on %s", campfire.object.id)
            --         tes3.playSound{
            --             sound = "ashfall_boil",
            --             reference = campfire
            --         }
            --     end
            -- end
        end)
    end

    ReferenceController.iterateReferences("fuelConsumer", doUpdate)
end

--[[
    When a save is first loaded, it may or may not trigger a cell change,
    depending on whether the previous save was in the same cell. So to ensure we
    don't initialise twice, we block the cellChange initialise from triggering on load,
    then call it a second later.
]]
local ignorePotentialLoadedCellChange
local function cellChanged()
    if not ignorePotentialLoadedCellChange then
        initialiseCampfireSoundAndFlame()
    end
end
event.register("cellChanged", cellChanged)

local function loaded()
    ignorePotentialLoadedCellChange = true
    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            ignorePotentialLoadedCellChange = false
        end
    }
    initialiseCampfireSoundAndFlame()
end
event.register("loaded", loaded)



-- Extinguish the campfire
local function extinguish(e)
    local campfire = e.fuelConsumer
    local playSound = e.playSound ~= nil and e.playSound or true

    tes3.removeSound{ reference = campfire, sound = "Fire" }

    --Remove light
    campfire:deleteDynamicLightAttachment()

    --Start and stop the torchout sound if necessary
    if playSound and campfire.data.isLit then
        timer.frame.delayOneFrame(function()
            tes3.playSound{ reference = campfire, sound = "Torch Out", loop = false }
            timer.start{
                type = timer.real,
                duration = 0.4,
                iterations = 1,
                callback = function()
                    tes3.removeSound{ reference = campfire, sound = "Torch Out" }
                end
            }
        end)
    end
    campfire.data.isLit = false
    campfire.data.burned = true
    campfire.data.hasColdFlame = nil
    if campfire.data.fuelLevel then
        --Reduce fuel level by 0.5, min of 0
        campfire.data.fuelLevel = math.max(0, campfire.data.fuelLevel - 0.5)
    end

    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end
event.register("Ashfall:fuelConsumer_Extinguish", extinguish)

local function reduceLightTime(itemData)
    if itemData and itemData.timeLeft then
        itemData.timeLeft = math.max(0, itemData.timeLeft - 10)
    end
end

local function lightFire(e)
    local fuelConsumer = e.fuelConsumer
    local lighterData = e.lighterData
    logger:debug("Lighting Fire %s", fuelConsumer.object.id)
    tes3.playSound{ reference = tes3.player, sound = "ashfall_light_fire"  }

    fuelConsumer.data.isLit = true
    --Only for campfires
    if ReferenceController.controllers.campfire:isReference(e.fuelConsumer) then
        fuelConsumer.data.burned = true
        fuelConsumer.data.fuelLevel = math.max(0, fuelConsumer.data.fuelLevel - 0.5)
        reduceLightTime(lighterData)
        tes3.playSound{ sound = "Fire", reference = fuelConsumer, loop = true }
        common.skills.survival:exercise(skillConfigs.survival.lightFire.skillGain)
    end
    event.trigger("Ashfall:UpdateAttachNodes", { reference = fuelConsumer})
    event.trigger("Ashfall:Campfire_Enablelight", { campfire = fuelConsumer})
end
event.register("Ashfall:fuelConsumer_Alight", lightFire)


local function createLightFromRef(ref)
    local lightNode = niPointLight.new()
    lightNode.name = "LIGHTNODE"
    if ref.object.color then
        lightNode.ambient = tes3vector3.new(0,0,0) --[[@as niColor]]
        lightNode.diffuse = tes3vector3.new(
            ref.object.color[1] / 255,
            ref.object.color[2] / 255,
            ref.object.color[3] / 255
        )--[[@as niColor]]
    else
        lightNode.ambient = tes3vector3.new(0,0,0) --[[@as niColor]]
        lightNode.diffuse = tes3vector3.new(255, 255, 255) --[[@as niColor]]
    end
    lightNode:setAttenuationForRadius(ref.object.radius)

    return lightNode
end

local function addLighting(e)
    local campfire = e.campfire
    local lightNode = createLightFromRef(campfire)
    local attachLight = campfire.sceneNode:getObjectByName("attachLight")
    if attachLight then
        attachLight:attachChild(lightNode)
        campfire.sceneNode:update()
        campfire.sceneNode:updateNodeEffects()
        campfire:deleteDynamicLightAttachment()
        campfire:getOrCreateAttachedDynamicLight(lightNode, 1.0)
    end
end
event.register("Ashfall:Campfire_Enablelight", addLighting)

