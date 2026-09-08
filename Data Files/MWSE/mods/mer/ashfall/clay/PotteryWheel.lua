local common = require("mer.ashfall.common.common")
local logger = common.createLogger("PotteryWheel")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager
local CarryableContainer = CraftingFramework.CarryableContainer
local RawClay = require("mer.ashfall.clay.RawClay")
local ShapingMenu = require("mer.ashfall.clay.ShapingMenu")
local Temper = require("mer.ashfall.clay.Temper")
local Decals = require("mer.ashfall.clay.Visuals.PotteryDecals")
local DampVisuals = require("mer.ashfall.clay.Dampness.DampVisuals")
---@class Ashfall.PotteryWheel: ItemInstance
---@field data Ashfall.SpinningWheelData
---@field registeredSpinningWheels table<string, boolean>
local PotteryWheel = {
    registeredSpinningWheels = {},
    ATTACH_NODE_NAME = "WHEEL_ATTACH",
    CLAY_BASE_MESH = "ashfall\\clay\\clay_base.nif",
    CLAY_BASE_2_MESH = "ashfall\\clay\\clay_base_2.nif",
    SPIN_DURATION = 10
}

---@class Ashfall.SpinningWheelData
---@field clayAmount number Amount of clay on the spinning wheel
---@field itemBeingProcessed string|nil The item id of the item being processed, if any
---@field isClayTempered boolean|nil Whether the clay on the wheel is tempered

local function saveBlocker()
    return false
end

local function blockSave()
    event.register("save", saveBlocker)
end

local function unblockSave()
    event.unregister("save", saveBlocker)
end


---Construct a new Spinning wheel instance
---@param reference tes3reference
---@return Ashfall.PotteryWheel|nil
function PotteryWheel:new(reference)
    if not PotteryWheel.isSpinningWheel(reference) then
        logger:warn("Reference is not a spinning wheel: %s", reference.baseObject.id)
        return nil
    end
    local potteryWheel = ItemInstance:new{
        reference = reference,
        dataKey = "Ashfall_SpinningWheel",
    }
    setmetatable(potteryWheel, self)
    self.__index = self

    CraftingFramework.Indicator.register{
        objectId = reference.baseObject.id,
    }

    return potteryWheel --[[@as Ashfall.PotteryWheel]]
end

--Get the amount of clay on the spinning wheel
---@return number
function PotteryWheel:getClayAmount()
    return self.data.clayAmount or 0
end

--Set the amount of clay on the spinning wheel
---@param amount number
function PotteryWheel:setClayAmount(amount)
    self.data.clayAmount = amount
end

function PotteryWheel:addClay(amount)
    local currentAmount = self:getClayAmount()
    self:setClayAmount(currentAmount + amount)
    self:updateVisuals()
end

---Get the item being processed on the spinning wheel
---@return string|nil The item id of the item being processed, if any
function PotteryWheel:getItemBeingProcessed()
    return self.data.itemBeingProcessed
end

---Add clay from the player's inventory to the spinning wheel
function PotteryWheel:addClayFromPlayer()
    logger:debug("Adding clay from player to spinning wheel: %s", self.reference.id)
    local temperedFilter = nil
    if self:getClayAmount() > 0 then
        temperedFilter = self.data.isClayTempered == true
    end
    RawClay.openSelectMenu(function(e)
        if not e.item then return end
        local tempered = Temper.isTempered{
            item = e.item,
            itemData = e.itemData,
        }
        self.data.isClayTempered = tempered
        self:addClay(1)
        CarryableContainer.removeItem{
            reference = tes3.player,
            item = e.item,
            itemData = e.itemData,
            count = 1,
            playSound = false,
        }
        logger:debug("Added clay to spinning wheel. Current clay amount: %d", self:getClayAmount())
    end, {
        tempered = temperedFilter
    })
end

---@return niNode?
function PotteryWheel:getAttachNode()
    return self.reference.sceneNode
        and self.reference.sceneNode:getObjectByName(PotteryWheel.ATTACH_NODE_NAME)
end

function PotteryWheel:updateVisuals()
    logger:debug("Updating spinning wheel visuals for: %s", self.reference.id)

    local visualsChanged = false
    local attachNode = self:getAttachNode()
    if not attachNode then
        logger:error("Spinning wheel attach node not found: %s", self.reference.id)
        return
    end

    local attachedClay = attachNode:getObjectByName("Ashfall_ClayMesh")
    local hasClay = self:getClayAmount() > 0
    if hasClay then

            logger:debug("Adding clay mesh to spinning wheel: %s", self.reference.id)

            local attachClayId = self:getClayAmount() > 1 and PotteryWheel.CLAY_BASE_2_MESH or PotteryWheel.CLAY_BASE_MESH
            local clayMesh = tes3.loadMesh(attachClayId):clone()
            clayMesh.name = "Ashfall_ClayMesh"
            attachNode:detachAllChildren()
            attachNode:attachChild(clayMesh)

            -- Apply dampness visuals to clay mesh (always wet-looking)
            DampVisuals.update(clayMesh, 1.0)

            visualsChanged = true

        -- Apply or remove temper decal based on current temper state
        local decals = Decals.get("temper") --[[@as Ashfall.Clay.PotteryDecals]]
        if self.data.isClayTempered then
            logger:debug("Applying temper decal to clay mesh on spinning wheel: %s", self.reference.id)
            decals:applyDecal(attachNode)
            visualsChanged = true
        else
            logger:debug("Removing temper decal from clay mesh on spinning wheel: %s", self.reference.id)
            decals:removeDecal(attachNode)
            visualsChanged = true
        end
    else
        if attachedClay then
            logger:debug("Removing clay mesh from spinning wheel: %s", self.reference.id)
            attachNode:detachChild(attachedClay)
            visualsChanged = true
        else
            logger:debug("Spinning wheel has no clay mesh to remove: %s", self.reference.id)
        end
    end

    if visualsChanged then
        self.reference.sceneNode:update()
        self.reference.sceneNode:updateEffects()
    end
end

---Swap out the static clay mesh with the recipe's animation mesh
function PotteryWheel:attachAnimNode(recipe)
    local attachNode = self:getAttachNode()
    if attachNode then
        logger:debug("Attaching clay animation mesh to spinning wheel: %s", self.reference.id)
        local animMesh = tes3.loadMesh(recipe.animationMesh):clone()
        animMesh.name = "Ashfall_ClayAnimMesh"
        attachNode:attachChild(animMesh)
        attachNode:update()
        attachNode:updateEffects()
        if self.data.isClayTempered then
            local decals = Decals.get("temper") --[[@as Ashfall.Clay.PotteryDecals]]
            if self.data.isClayTempered then
                decals:applyDecal(attachNode)
            else
                decals:removeDecal(attachNode)
            end
        end

        -- Apply dampness visuals to animation mesh (always wet-looking)
        DampVisuals.update(animMesh, 1.0)
    end
end

function PotteryWheel:spin()
    tes3.playSound{
        soundPath = "ashfall\\wheel.wav",
        reference = self.reference,
    }
    tes3.playAnimation{
        reference = self.reference,
        group = tes3.animationGroup.idle2,
        loopCount = 0,
        startFlag = tes3.animationStartFlag.immediate
    }
end

function PotteryWheel:removeAnimNode()
    logger:debug("Removing clay animation mesh from spinning wheel: %s", self.reference.id)
    local attachNode = self:getAttachNode()
    if attachNode then
        local animMesh = attachNode:getObjectByName("Ashfall_ClayAnimMesh")
        if animMesh then
            attachNode:detachChild(animMesh)
            attachNode:update()
            attachNode:updateEffects()
        end
    else
        logger:warn("Spinning wheel attach node not found: %s", self.reference.id)
    end
end

function PotteryWheel:getAttachNodeGlobalPosition()
    local attachNode = self:getAttachNode()
    if attachNode then
        local niPos = attachNode.worldTransform.translation
        return tes3vector3.new(niPos.x, niPos.y, niPos.z)
    end
    logger:error("Spinning wheel attach node not found: %s", self.reference.id)
    return self.reference.position:copy()
end

local NormalsHack = require("mer.ashfall.clay.Util.NormalsHack")

---@param recipe Ashfall.PotteryRecipe
function PotteryWheel:startSpinning(recipe)
    self.data.itemBeingProcessed = recipe.id
    --Remove clay
    self:setClayAmount(0)
    self:updateVisuals()

    --disable player controls
    common.helper.disableControls()
    tes3.mobilePlayer.mouseLookDisabled = false
    blockSave()

    --Start animation
    self:attachAnimNode(recipe)
    self:spin()

    local attachNode = self:getAttachNode()
    local animMesh = attachNode and attachNode:getObjectByName("Ashfall_ClayAnimMesh")
    local data = (animMesh).children[1].data --[[@as niTriShapeData]]
    local function fixNormals()
        NormalsHack.fixNormals(data)
    end
    local function onInvalidated(e)
        if e.object == self.reference then
            event.unregister("simulate", fixNormals)
        end
    end

    event.register("simulate", fixNormals)
    event.register("objectInvalidated", onInvalidated)

    self:setAnimatingState(true)
    timer.start{
        type = timer.real,
        duration = PotteryWheel.SPIN_DURATION,
        callback = function()
            logger:debug("Spinning wheel processing complete: %s", self.reference.id)
            common.helper.enableControls()
            unblockSave()
            event.unregister("simulate", fixNormals)
            event.unregister("objectInvalidated", onInvalidated)
            self:setAnimatingState(false)
            self:replaceAnimMeshWithItem()
            common.skills.pottery:exercise(recipe.difficulty)
        end
    }
end

---Places the pottery item in at the global position of the anim mesh and removes the anim mesh from the wheel
function PotteryWheel:replaceAnimMeshWithItem()
    local itemBeingProcessed = self:getItemBeingProcessed()
    if not itemBeingProcessed then
        logger:error("No item being processed on spinning wheel: %s", self.reference.id)
        return
    end
    local position = self:getAttachNodeGlobalPosition()

    UnfiredPottery.createPotteryRef{
        objectId = itemBeingProcessed,
        cell = self.reference.cell,
        position = position,
        orientation = self.reference.orientation,
        tempered = self.data.isClayTempered == true,
    }

    self.data.itemBeingProcessed = nil
    self.data.isClayTempered = nil

    self:removeAnimNode()
    self:updateVisuals()
end

function PotteryWheel:setAnimatingState(isAnimating)
    self.reference.tempData.Ashfall_SpinningWheel_isAnimating = isAnimating
end

function PotteryWheel:isAnimating()
    return self.reference.tempData.Ashfall_SpinningWheel_isAnimating
end

---Open the clay molding menu for this spinning wheel
function PotteryWheel:openMoldingMenu()
    ShapingMenu:new{
        title = "Pottery Wheel",
        clayId = RawClay.rawClayId,
        isTempered = self.data.isClayTempered,
        clayAmount = self:getClayAmount(),
        recipes = PotteryRecipe.getAllRecipesByMethod("wheel"),
        okayCallback = function(results)
            timer.delayOneFrame(function()
                local recipe = PotteryRecipe.getRecipeByRawItemId(results.selectedShapeId)
                if not recipe then
                    logger:error("No recipe found for selected shape id: %s", results.selectedShapeId)
                    return
                end
                local clayAmount = recipe.clayAmount
                self:addClay(-clayAmount)
                self:startSpinning(recipe)
            end)
        end,
        hasTemper = self.data.isClayTempered,
    }:show()

end

function PotteryWheel:takeClay()
    local clayAmount = self:getClayAmount()
    self:setClayAmount(0)
    tes3.addItem{
        reference = tes3.player,
        item = RawClay.rawClayId,
        count = clayAmount,
        playSound = true,
    }
    if self.data.isClayTempered then
        local itemData = tes3.addItemData{
            to = tes3.player,
            item = RawClay.rawClayId,
        }
        if itemData then
            local tempered = Temper:new{
                item = tes3.getObject(RawClay.rawClayId),
                itemData = itemData,
            }
            if tempered then
                tempered:addTemper()
                logger:debug("Added temper to clay taken from spinning wheel")
            end
        else
            logger:error("Failed to add temper to clay taken from spinning wheel")
        end
    end

    self.data.isClayTempered = nil
    self:updateVisuals()
    logger:debug("Removed clay from spinning wheel")
end


ReferenceManager:new{
    requirements = function(self, reference)
        return PotteryWheel.isSpinningWheel(reference)
    end,
    onActivated = function(self, reference)
        local potteryWheel = PotteryWheel:new(reference)
        if not potteryWheel then return end
        potteryWheel:updateVisuals()
        local itemBeingProcessed = potteryWheel:getItemBeingProcessed()
        if itemBeingProcessed then
            --On load, we attach the itemBeingProcessed mesh instead of the animation
            local item = tes3.getObject(itemBeingProcessed)
            local attachNode = potteryWheel:getAttachNode()
            if attachNode then
                logger:debug("Re-attaching processing mesh on load for: %s", reference.id)
                local mesh = tes3.loadMesh(item.mesh):clone()
                mesh.name = "Ashfall_ClayAnimMesh"
                attachNode:attachChild(mesh)
                attachNode:update()
                attachNode:updateEffects()
            end
        end
        tes3.playAnimation{
            reference = reference,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate
        }
        logger:debug("Spinning wheel referenceactivated: %s", reference.id)
    end,
}

---@param isTempered boolean|nil Whether the clay being added is tempered. If provided, must match the temper state of the clay already on the whee
function PotteryWheel:canAddClay(isTempered)
    local temperMatches = (isTempered == nil)
        or (self.data.isClayTempered == nil)
        or isTempered == (self.data.isClayTempered == true)

    return self:getClayAmount() < 2
        and self:getItemBeingProcessed() == nil
        and temperMatches
end


---@type craftingFrameworkMenuButtonData[]
PotteryWheel.buttons = {
    {
        text = "Shape",
        showRequirements = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then
                logger:error("Failed to create spinning wheel instance for reference: %s", e.reference.id)
                return false
            end
            return potteryWheel:getItemBeingProcessed() == nil
                and potteryWheel:getClayAmount() > 0
        end,
        callback = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return end
            potteryWheel:openMoldingMenu()
        end
    },
    {
        text = "Add Clay",
        showRequirements = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return false end
            local clayInInventory = RawClay.getPlayerClayInInventory()
            return clayInInventory > 0
                and potteryWheel:canAddClay()
        end,
        enableRequirements = function(e)
            local clayInInventory = RawClay.getPlayerClayInInventory()
            return clayInInventory > 0
        end,
        tooltipDisabled = function()
            return { text = "You have no raw clay in your inventory." }
        end,
        callback = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return end
            potteryWheel:addClayFromPlayer()
        end
    },
    {
        text = "Add Temper",
        showRequirements = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return false end
            return potteryWheel:getClayAmount() > 0
                and not potteryWheel.data.isClayTempered
                and potteryWheel:getItemBeingProcessed() == nil
        end,
        enableRequirements = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return false end
            local clayAmount = potteryWheel:getClayAmount()
            local hasTemper = Temper.getPlayerTemperCount() >= clayAmount
            local hasMortarAndPestle = require("mer.ashfall.clay.MortarAndPestle").playerHasMortarAndPestle()
            return hasTemper and hasMortarAndPestle
        end,
        tooltip = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return nil end
            local clayAmount = potteryWheel:getClayAmount()
            return {
                header = "Requirements:",
                text = string.format("- %dx Broken Pottery\n- Mortar and Pestle", clayAmount),
            }
        end,
        tooltipDisabled = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return nil end
            local clayAmount = potteryWheel:getClayAmount()
            return {
                header = "Requirements:",
                text = string.format("- %dx Broken Pottery\n- Mortar and Pestle", clayAmount),
            }
        end,
        callback = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return end

            local clayAmount = potteryWheel:getClayAmount()
            CarryableContainer.removeItem{
                reference = tes3.player,
                item = Temper.temperId,
                count = clayAmount,
                playSound = false,
            }
            tes3.playSound{
                reference = e.reference,
                sound = "corpDRAG"
            }

            timer.start{
                type = timer.real,
                duration = 1.5,
                callback = function()
                    potteryWheel.data.isClayTempered = true
                    potteryWheel:updateVisuals()
                    tes3.playSound{
                        reference = e.reference,
                        sound = "corpDRAG"
                    }
                    logger:debug("Added temper to clay on pottery wheel: %s", e.reference.id)
                end
            }
            common.helper.fadeTimeOut(0.2, 3, function() end)
        end
    },
    {
        text = "Remove Clay",
        showRequirements = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return false end
            return potteryWheel:getClayAmount() > 0
                and potteryWheel:getItemBeingProcessed() == nil
        end,
        callback = function(e)
            local potteryWheel = PotteryWheel:new(e.reference)
            if not potteryWheel then return end
            potteryWheel:takeClay()
        end
    },
}


function PotteryWheel.registerIndicator(spinningWheelId)
    CraftingFramework.Indicator.register{
        objectId = spinningWheelId,
        additionalUI = function(indicator, parentElement)
            --Show clay amount and processed item
            local potteryWheel = PotteryWheel:new(indicator.reference)
            if not potteryWheel then return end
            local itemBeingProcessed = potteryWheel:getItemBeingProcessed()
            local clayAmount = potteryWheel:getClayAmount()
            local isAnimating = potteryWheel:isAnimating()

            if not isAnimating then
                local text
                local node = indicator.nodeLookingAt
                logger:trace("PotteryWheel indicator node: %s", node and node.name or "nil")
                if itemBeingProcessed then
                    local item = tes3.getObject(itemBeingProcessed)
                    text = item.name
                elseif clayAmount > 0 then
                    text = potteryWheel.data.isClayTempered and "Tempered Clay" or "Raw Clay"
                    if clayAmount > 1 then
                        text = string.format("%s x%d", text, clayAmount)
                    end
                end
                if text then
                    parentElement:createLabel{ text = text }
                end
            end
        end
    }
end

---Check if a reference is a registered spinning wheel
---@param reference tes3reference
---@return boolean
function PotteryWheel.isSpinningWheel(reference)
    return PotteryWheel.registeredSpinningWheels[reference.baseObject.id:lower()] ~= nil
end

---Register a spinning wheel by id
---@param id string
function PotteryWheel.registerSpinningWheel(id)
    PotteryWheel.registeredSpinningWheels[id:lower()] = true
    PotteryWheel.registerIndicator(id)
    logger:info("Registered spinning wheel: %s", id)
end


function PotteryWheel.getOnDropConfig()
    return {
        dropText = function()
            return "Add Clay"
        end,
        canDrop = function(reference, item, itemData)
            if item.id:lower() ~= RawClay.rawClayId then
                return false
            end
            local isTempered = Temper.isTempered{
                item = item,
                itemData = itemData,
            }
            local potteryWheel = PotteryWheel:new(reference)
            if not potteryWheel then return false end
            return potteryWheel:canAddClay(isTempered == true)
        end,
        onDrop = function(wheelRef, clayRef)
            local potteryWheel = PotteryWheel:new(wheelRef)
            if not potteryWheel then return end

            potteryWheel.data.isClayTempered = Temper.isTempered{ reference = clayRef}
            potteryWheel:addClay(1)

            local stackCount = common.helper.getStackCount(clayRef)
            if stackCount == 1 then
                clayRef:delete()
            else
                clayRef.attachments.variables.count = clayRef.attachments.variables.count - 1
                common.helper.pickUp(clayRef)
            end
        end
    }
end

return PotteryWheel