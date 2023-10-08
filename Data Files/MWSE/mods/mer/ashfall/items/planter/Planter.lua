local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.items.planter.config")
local Seedling = require("mer.ashfall.items.planter.Seedling")
local LiquidContainer   = require("mer.ashfall.liquid.LiquidContainer")
local ActivatorController = require "mer.ashfall.activators.activatorController"

---@class Ashfall.Planter
---@field reference tes3reference The reference of the planter.
---@field waterAmount number The amount of water in the planter, determines how fast it grows.
---@field seedlingId string The id of the ingredient used to plant this planter.
---@field plantId string The id of the plant container assigned to this planter.
---@field maxScale number The maximum scale this plant can grow to.
---@field plantProgress number The growth progress of the plant, 0.0-1.0. Becomes a fully harvestable plant at 1.0.
---@field timeUntilHarvestable number The time to wait until the plant is harvestable.
---@field attachPlant function Attaches a plant to the planter.
---@field waterPlanter function Water the planter.
---@field lastUpdated number The last time the planter was updated.
---@field logger mwseLogger
local Planter = {
    ATTACH_NODE = "ATTACH_PLANT",
    GH_SWITCH_ID = "HerbalismSwitch",
    GH_NORMAL_INDEX = 0,
    GH_HARVESTED_INDEX = 1,
    --growth
    WATER_PER_GROWTH_HOUR= 1, --how much water is consumed per hour of growth
    UNWATERED_HOURS_TO_GROW = common.helper.weeksToHours(2), --how many hours it takes to grow when unwatered
    WATER_GROWTH_MULTI = 4, --How much faster it grows when watered
    --recovery
    WATER_PER_RECOVERY_HOUR = 1, --how much water is consumed per hour of recovery
    WATER_RECOVER_MULTI = 4, --How much faster it recovers when watered
    MIN_UNWATERED_HOURS_TO_HARVEST = common.helper.daysToHours(6), -- minimum hours it takes to recover when unwatered
    MAX_UNWATERED_HOURS_TO_HARVEST = common.helper.daysToHours(10), -- maximum hours it takes to recover when unwatered
    --water
    MAX_WATER_AMOUNT = 50, --maximum amount of water the planter can hold
    WATER_PER_HOUR_RAIN = 200, --how much water is added per hour when raining
    WATER_PER_HOUR_THUNDER = 400, --how much water is added per hour when raining
}

Planter.logger = common.createLogger("Planter")

--[[
    Defines which values are stored on the reference's data table,
    and what their default values are.
]]
local defaultDataValues = {
    waterAmount = {default = 0},
    seedlingId = {default = nil},
    plantId = {default = nil},
    plantProgress = {default = 0},
    timeUntilHarvestable = {default = 0},
    maxScale = {default = nil},
    lastUpdated = {default = nil},
}

--[[
    For any data value, get it from the reference's data table if it exists
]]
local meta = {
    ---@param tbl Ashfall.Planter
    ---@param key any
    __index = function(tbl, key)
        if Planter[key] then return Planter[key] end
        if defaultDataValues[key] then
            if not tbl.reference.supportsLuaData then
                return defaultDataValues[key].default
            end
            local val = tbl.reference.data[key] or defaultDataValues[key].default
            return val
        end
    end,
    ---@param self Ashfall.Planter
    ---@param key any
    ---@param val any
    __newindex = function(self, key, val)
        if defaultDataValues[key] then
            self.reference.data[key] = val
        else
            rawset(self, key, val)
        end
    end,
    __tostring = function(self)
        return self.seedlingId
            and string.format("%s(%s)",self.reference.object.id, self.seedlingId)
            or self.reference.object.id
    end,
}

--[[
    Construct a new Planter from a given reference
]]
---@param reference tes3reference
---@return Ashfall.Planter|nil
Planter.new = function(reference)
    if not Planter.isPlanter(reference) then
        return
    end
    local planter = {
        reference = reference,
        logger = common.createLogger("Planter(" .. reference.object.id .. ")"),
    }
    setmetatable(planter, meta)
    return planter
end

function Planter:getDirtNode()
    local node = self.reference.sceneNode:getObjectByName("ASHFALL_SOIL")
    return node
end

function Planter:updateDirtWater()
    local dirtNode = self:getDirtNode()
    local strength = math.remap(self.waterAmount / self.MAX_WATER_AMOUNT, 0, 1.0, 0.8, 0.0)
    self.logger:trace("Setting water darkness strength to %s", strength)
    local colours = {
        r = strength,
        g = strength,
        b = strength,
    }
    local materialProperty = dirtNode:detachProperty(0x2):clone()
---@diagnostic disable-next-line: param-type-mismatch
    dirtNode:attachProperty(materialProperty)
    materialProperty.emissive = colours
    dirtNode:updateProperties()
end

function Planter:updateDirtTexture()
    self.logger:trace("Updating dirt texture")
    local dirtNode = self:getDirtNode()
    if dirtNode then
        local groundTextureInfo = common.helper.getGroundTextureInfo{
            position = {
                self.reference.position.x,
                self.reference.position.y,
                self.reference.position.z + 1000,
            },
            direction = {0, 0, -1}
        }
        if groundTextureInfo then
            local textureMaps = groundTextureInfo.texturingProperty.maps
            local patterns = { "dirt","sand","mud","coastal","ashlands",
                "grass","moss","snow","pine","gravel",}
            for _, pattern in ipairs(patterns) do
                ---@param map niTexturingPropertyMap
                for i, map in ipairs(textureMaps) do
                    if map and map.texture then
                        self.logger:trace("map %d, texture: %s", i, map.texture.fileName)
                        self.logger:trace("fileName: %s", groundTextureInfo.texturingProperty.maps[1].texture.fileName)
                        if string.find(map.texture.fileName:lower(), pattern) then
                            self.logger:trace("updating texture to %s", map.texture.fileName)
                            local clonedProp = dirtNode:detachProperty(0x4):clone()
                            ---@diagnostic disable-next-line: param-type-mismatch
                            dirtNode:attachProperty(clonedProp)
                            dirtNode.texturingProperty.baseMap.texture = map.texture
                            dirtNode:updateProperties()
                            return
                        end
                    end
                end
            end
        else
            self.logger:trace("No ground texture info")
        end
    else
        self.logger:trace("No soil node")
    end
end

function Planter:getGHSwichNode()
    local sceneNode = self.reference and self.reference.sceneNode
    if not sceneNode then return end
    return sceneNode:getObjectByName(Planter.GH_SWITCH_ID)
end

function Planter:getPlantNode()
    local sceneNode = self.reference and self.reference.sceneNode
    if not sceneNode then return end
    return sceneNode:getObjectByName(Planter.ATTACH_NODE)
end

function Planter:canRecover()
    --Find the HARVESTED node and check if it has any children.
    --If it has no children, that means there's nothing left of the plant when it's harvested

    local ghInstalled = include("graphicHerbalism.interop") ~= nil
    if not ghInstalled then
        self.logger:trace("GH is not installed, everything is recoverable")
        return true
    end

    local ghNode = self:getGHSwichNode()
    if not ghNode then
        self.logger:trace("GH is installed but this ref has no herbalism switch, so make this non-recoverable")
        return false
    end

    --Navigates a mesh to find if there are any trishapes outside of the un-harvested switch node.
    local function sceneNodeHasHarvestedShapes(node)
        if node == nil then return false end
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then return false end
        if node.name == "NORMAL" then return false end
        if node:isInstanceOfType(tes3.niType.NiNode) then
            for i = 1, #node.children do

                if sceneNodeHasHarvestedShapes(node.children[i]) == true then
                    return true
                end
            end
            return false
        end
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            self.logger:trace("Found triShape %s", node.name)
            return true
        end
        return false
    end
    self.logger:trace("Checking if scene node has harvested shapes")
    local canRecover = sceneNodeHasHarvestedShapes(self:getPlantNode())
    self.logger:trace("%s", canRecover and
        "Trishapes found outside NORMAL node, can recover"
        or "No trishapes found outside NORMAL node, can't recover")
    return canRecover
end

--[[
    If Graphic Herbalism is installed, update the switch nodes to show whether the plant is harvested or not
]]
function Planter:updateGHNodes()
    self.logger:trace("updating gh nodes")
    local ghNode = self:getGHSwichNode()
    if not ghNode then
        self.logger:trace("No herbalism switch, skip update")
        return
    end
    local showHarvested = self:isFullyGrown() and not self:readyToHarvest()
    local switchIndex = showHarvested and Planter.GH_HARVESTED_INDEX or Planter.GH_NORMAL_INDEX
    local currentIndex = ghNode.switchIndex
    if currentIndex ~= switchIndex then
        self.logger:trace("Updating GH switch index from %d to %d", currentIndex, switchIndex)
        ghNode.switchIndex = switchIndex
    end
end

--[[
    Attach a plant mesh to the planter.
]]
function Planter:updatePlantMesh()
    self.logger:trace("Updating plant mesh")
    local attachNode = self.reference.sceneNode:getObjectByName(Planter.ATTACH_NODE)--[[@as niNode]]
    if not attachNode then
        self.logger:error("No %s node found", Planter.ATTACH_NODE)
        return
    end
    self.logger:trace("Removing any existing mesh from attach node")
    attachNode:detachChildAt(1)

    if not self.seedlingId then
        self.logger:trace("No seedling Id, leaving empty")
        return
    end
    local plant = tes3.getObject(self.plantId)
    if not plant then
        self.logger:error("No plant found for %s", self.seedlingId)
        return
    end

    do --attach plant mesh
        self.logger:trace("Attaching plant %s", plant)
        local mesh = tes3.loadMesh(plant.mesh, false):clone() --[[@as niNode]]
        if not mesh then
            self.logger:error("No mesh found for %s", plant)
            return
        end

        self.logger:trace("Mesh: %s", mesh)
        --Get Z from bounding box for offset
        local bbox = mesh:createBoundingBox()
        self.logger:trace("BB.min.z: %s", bbox.min.z)
        local height = bbox.max.z - bbox.min.z
        local zoffset = bbox.min.z + height * 0.2
        mesh.translation.z = mesh.translation.z - zoffset * mesh.scale

        --Center the mesh because fucking Bethesda
        local xOffset = (bbox.max.x + bbox.min.x) * 0.5
        self.logger:trace("xOffset: %s", xOffset)
        mesh.translation.x = mesh.translation.x - xOffset * mesh.scale

        local yOffset = (bbox.max.y + bbox.min.y) * 0.5
        self.logger:trace("yOffset: %s", yOffset)
        mesh.translation.y = mesh.translation.y - yOffset * mesh.scale

        ---@diagnostic disable-next-line: param-type-mismatch
        attachNode:attachChild(mesh)

        attachNode.scale = math.remap(self.plantProgress, 0.0, 1.0, 0.1, self:getMaxScale())
        self.reference:updateSceneGraph()
        attachNode:update()
        ---@diagnostic disable-next-line
        attachNode:updateNodeEffects()

        self:updateGHNodes()
    end
end

function Planter:getMaxScale()
    if self.maxScale then
        self.logger:trace("Max scale for %s is %s", self.plantId, self.maxScale)
        return self.maxScale
    end
    local maxScale = 1.0
    local plantConfig = config.plantConfigs[self.plantId:lower()]
    if plantConfig and plantConfig.maxScale then
        maxScale = plantConfig.maxScale
    end
    local existingRef = tes3.getReference(self.plantId)
    if existingRef then
        self.logger:trace("Existing ref scale: %s", existingRef.scale)
        maxScale = math.min(maxScale, existingRef.scale)
    end
    self.logger:trace("Max scale for %s is %s", self.plantId, maxScale)

    --Limit to width of planter
    local planterWidth = math.max(
        self.reference.object.boundingBox.max.x - self.reference.object.boundingBox.min.x,
        self.reference.object.boundingBox.max.y - self.reference.object.boundingBox.min.y
    )
    planterWidth = planterWidth * 1.25 --Add padding

    local bbox = tes3.loadMesh(tes3.getObject(self.plantId).mesh):createBoundingBox()
    local plantWidth = math.max(
        bbox.max.x - bbox.min.x,
        bbox.max.y - bbox.min.y
    )
    if plantWidth > planterWidth then
        self.logger:debug("plant is bigger than planter, limiting scale to %s", planterWidth / plantWidth)
        maxScale = math.min(maxScale, planterWidth/plantWidth)
    end

    self.maxScale = maxScale
    return maxScale
end

---@param self Ashfall.Planter
---@param ingredient tes3ingredient
function Planter:plantSeed(ingredient)
    if self.seedlingId then
        self.logger:error("Already has plant %s, cannot plant another", self.seedlingId)
        return
    end
    local seedling = Seedling:new(ingredient)
    if seedling then
        local plantObj = seedling:pickPlant()
        if plantObj then
            self:resetPlantValues()
            self.seedlingId = seedling.ingredient.id
            self.plantId = seedling:pickPlant().id
            event.trigger("Ashfall:registerReference", { reference = self.reference})
            self:updatePlantMesh()
        else
            self.logger:error("No plant found for %s", ingredient)
        end
    else
        self.logger:error("Unable to create seedling for %s", ingredient)
    end
end

---@return number How many hours have passed since growth was updated
function Planter:getHoursSinceUpdate()
    self.lastUpdated = self.lastUpdated or tes3.getSimulationTimestamp()
    local hoursPassed = tes3.getSimulationTimestamp() - self.lastUpdated
    return hoursPassed
end

function Planter:updateLastUpdated()
    self.lastUpdated = tes3.getSimulationTimestamp()
end

function Planter:doRainWater(hoursPassed)
    local sheltered = common.helper.checkRefSheltered(self.reference)
    if sheltered then
        self.logger:trace("Planter is sheltered, not getting rain water")
        return
    end
    local rainPerHour
     --raining
    if tes3.getCurrentWeather().index == tes3.weather.rain then
        rainPerHour = self.WATER_PER_HOUR_RAIN
    --thunder
    elseif tes3.getCurrentWeather().index == tes3.weather.thunder then
        rainPerHour = self.WATER_PER_HOUR_THUNDER
    end
    if rainPerHour then
        self.logger:trace("Rain water per hour: %s", rainPerHour)
        local rainAmount = rainPerHour * hoursPassed
        self.logger:trace("Rain water amount: %s", rainAmount)
        --We add a little bit more to the max because when a plant is growing it always drops down a bit, so it would never say 50
        self.waterAmount = math.clamp(self.waterAmount + rainAmount, 0, self.MAX_WATER_AMOUNT + 0.1)
        self.logger:trace("Water amount after rain: %s", self.waterAmount)
        self:updateDirtWater()
    end
end

function Planter:grow(hoursPassed)
    self.logger:trace("Growing plant, hours passed: %s", hoursPassed)
    local growthAmount = hoursPassed / self.UNWATERED_HOURS_TO_GROW
    if self:hasWater() then
        growthAmount = growthAmount * self.WATER_GROWTH_MULTI
        self.logger:trace("Watered growth: %s", growthAmount)
        local waterUsed = hoursPassed * self.WATER_PER_GROWTH_HOUR
        self.logger:trace("Water used: %s", waterUsed)
        self.waterAmount = math.max(self.waterAmount - waterUsed, 0)
        self:updateDirtWater()
    else
        self.logger:trace("Unwatered growth amount: %s", growthAmount)
    end
    self.plantProgress = math.clamp(self.plantProgress + growthAmount, 0, 1)
    self:updatePlantMesh()
end

---Update the plant's growth, water, and recovery
function Planter:progress()
    self.logger:trace("Progressing %s", self.reference)
    local hoursPassed = self:getHoursSinceUpdate()
    self:updateLastUpdated()
    self:doRainWater(hoursPassed)
    if not self:hasPlant() then return end
    if self:isFullyGrown() then
        self.logger:trace("fully grown")
        if not self:readyToHarvest() then
            self:recover(hoursPassed)
            self.logger:trace("Plant is fully grown")
            self:updateGHNodes()
        end
    else
        self:grow(hoursPassed)
    end
    tes3ui.refreshTooltip()
end

---Recover the plant over time after harvesting
function Planter:recover(hoursPassed)
    if self:readyToHarvest() then return end
    if not self:hasPlant() then return end
    self.logger:trace("Recovering plant, hours passed: %s", hoursPassed)
    local recoverAmount = hoursPassed
    if self:hasWater() then
        recoverAmount = hoursPassed * self.WATER_RECOVER_MULTI
        self.timeUntilHarvestable = self.timeUntilHarvestable - hoursPassed
        self.logger:trace("Watered recovery amount: %s", recoverAmount)
        local waterUsed = hoursPassed * self.WATER_PER_RECOVERY_HOUR
        self.logger:trace("Water used: %s", waterUsed)
        self:reduceWater(waterUsed)
    else
        self.logger:trace("Unwatered recovery amount: %s", recoverAmount)
    end
    self.timeUntilHarvestable = self.timeUntilHarvestable - recoverAmount
end

---Reduce the water in the planter by a given amount
function Planter:reduceWater(amount)
    self.waterAmount = math.max(self.waterAmount - amount, 0)
    self:updateDirtWater()
end

---Add water to the planter from a liquid container
---@param liquidContainer Ashfall.LiquidContainer How much water to add
---@return number How much water was left over
function Planter:water(liquidContainer)
    self.logger:debug("Watering")
    local data = {
        waterAmount = self.waterAmount
    }
    local bottleData = {
        capacity = self.MAX_WATER_AMOUNT,
        holdsStew = false
    }
    local thisLiquidContainer = LiquidContainer.createFromData(data, bottleData)
    if not thisLiquidContainer then
        self.logger:error("Unable to create liquid container")
        return 0
    end
    local waterLeft = liquidContainer:transferLiquid(thisLiquidContainer)
    self.waterAmount = data.waterAmount
    self:updateDirtWater()
    return waterLeft
end

function Planter:resetTimeToHarvest()
    local newTimeToHarvest = math.random(self.MIN_UNWATERED_HOURS_TO_HARVEST, self.MAX_UNWATERED_HOURS_TO_HARVEST)
    self.logger:debug("Resetting time to harvest to %s", newTimeToHarvest)
    self.timeUntilHarvestable = newTimeToHarvest
end

function Planter:resetPlantValues()
    self.plantId = nil
    self.seedlingId = nil
    self.plantProgress = 0
    self.timeUntilHarvestable = 0
    self.maxScale = nil
    self.lastUpdated = nil
end

function Planter:removePlant()
    self:resetPlantValues()
    self:updatePlantMesh()
    self.logger:debug("Plant removed")
end

function Planter:addItems()
    self.logger:debug("adding items")
    local plant = tes3.getObject(self.plantId)
    self.logger:debug("plant: %s", plant.id)
    ---@param stack tes3itemStack
    for _, stack in pairs(plant.inventory) do
        self.logger:debug("item: %s count: %s", stack.object.id, stack.count)
        local item = stack.object
        local count = stack.count + 1
        if item.objectType == tes3.objectType.leveledItem then
            local leveledItem = item --[[@as tes3leveledItem]]
            ---@diagnostic disable-next-line
            item = leveledItem:pickFrom()
        end
        if item then
            tes3.addItem{
                reference = tes3.player,
                item = item,
                count = count,
                playSound = false
            }
            tes3.messageBox(string.format("You harvested %s %s.", count, item.name))
        end
    end
end

function Planter:harvest()
    self.logger:debug("Harvesting")
    if not self:readyToHarvest() then
        self.logger:error("Not ready to harvest")
        return
    end
    self:addItems()
    tes3.playSound{ sound = "Item Misc Up"}
    if self:canRecover() then
        self:resetTimeToHarvest()
        self:updateGHNodes()
    else
        self:removePlant()
    end
end

function Planter:getTooltipMessages()
    local messages = {}
    if self.waterAmount > 0 then
        table.insert(messages,
            string.format("Water: %d/%d", math.floor(self.waterAmount), self.MAX_WATER_AMOUNT))
    end
    if self.plantId then
        if self.plantProgress < 1 then
            table.insert(messages, string.format("Growth: %d%%", self.plantProgress*100))
        else
            table.insert(messages,
                (self.timeUntilHarvestable > 0) and "Harvested" or "Ready to harvest")
        end
        local plant = tes3.getObject(self.plantId)
        if plant then
            table.insert(messages, plant.name)
        end
    end
    return messages
end

function Planter:isFullyGrown()
    return self.plantProgress >= 1
end

function Planter:readyToHarvest()
    return self:isFullyGrown() and self.timeUntilHarvestable <= 0
end

function Planter:canBeWatered()
    return self.waterAmount < self.MAX_WATER_AMOUNT - 1
end

function Planter:hasWater()
    return self.waterAmount > 0
end

function Planter:hasPlant()
    return self.plantId ~= nil
end

function Planter.filterPlantable(item)
    return Seedling.isSeedling(item)
end

Planter.placeCallback = function(_, e)
    local reference = e.reference
    local planter = Planter.new(reference)
    if planter then
        planter:updatePlantMesh()
        planter:updateDirtTexture()
        planter:updateDirtWater()
    end
end

Planter.destroyCallback = function(_, e)
    local reference = e.reference
    local planter = Planter.new(reference)
    if planter and planter.seedlingId then
        tes3.addItem{
            reference = tes3.player,
            item = planter.seedlingId,
            count = 1,
            playSound = false,
            showMessage = true,
        }
    end
end

--- Checks for required nodes that make the reference a valid planter.
Planter.isPlanter = function(reference)
    return reference.sceneNode
        and reference.sceneNode:getObjectByName("ASHFALL_SOIL") ~= nil
        and reference.sceneNode:getObjectByName("ATTACH_PLANT") ~= nil
end

Planter.buttons = {
    harvest = {
        text = "Harvest",
        showRequirements = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            return planter and planter:readyToHarvest()
        end,
        callback = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            planter:harvest()
        end
    },
    plantSeed = {
        text = "Plant",
        tooltip = function()
            return common.helper.showHint(
                "You can plant seeds by dragging them from your inventory directly onto the planter."
            )
        end,
        showRequirements = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return false end
            if planter.seedlingId then
                return false
            end
            return planter and planter.plantId == nil
        end,
        callback = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            timer.delayOneFrame(function()
                tes3ui.showInventorySelectMenu{
                    title = "Select Plant",
                    noResultsText = "You don't have any plantable items.",
                    filter = function(e)
                        return Planter.filterPlantable(e.item)
                    end,
                    callback = function(e)
                        if e.item then
                            planter:plantSeed(e.item)
                            tes3.removeItem{
                                reference = tes3.player,
                                item = e.item,
                                itemData = e.itemData,
                                count = 1,
                                playSound = false,
                            }
                        end
                    end,
                }
            end)
        end,
    },
    water = {
        text = "Water",
        tooltip = function()
            return common.helper.showHint(
                "You can water a plant by dragging a water container directly onto it."
            )
        end,
        tooltipDisabled = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            local hasRoomForWater = planter.waterAmount < planter.MAX_WATER_AMOUNT - 1
            if not hasRoomForWater then
                return{text = "Planter is already full of water"}
            end
        end,
        enableRequirements = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            local hasRoomForWater = planter:canBeWatered()
            if not hasRoomForWater then
                return false, "Planter is already full of water"
            end
            return hasRoomForWater
        end,
        callback = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            timer.delayOneFrame(function()
                tes3ui.showInventorySelectMenu{
                    title = "Select Water Container",
                    noResultsText = "You don't have any water.",
                    filter = function(e)
                        local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                        return liquidContainer ~= nil
                            and liquidContainer:isWater()
                            and liquidContainer:hasWater()
                    end,
                    callback = function(e)
                        if e.item and e.itemData then
                            local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                            if liquidContainer then
                                planter:water(liquidContainer)
                            end
                        end
                    end,
                }
            end)
        end,
    },
    removePlant = {
        text = "Remove Plant",
        showRequirements = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            return planter and planter:hasPlant()
        end,
        callback = function(e)
            local reference = e.reference or e
            local planter = Planter.new(reference)
            if not planter then return end
            tes3.addItem{
                reference = tes3.player,
                item = planter.seedlingId,
                showMessage = true,
            }
            planter:removePlant()
        end
    },
}



return Planter