local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config

local crabpotConfig = {
    maxCrabs = 3,
    --1 crab every 4 days in a non-crab cell, at minimum depth, at 0 survival skill
    crabsPerHour = (1/96),
    variance = 0.25,
    --When crabs are present, catch rate goes up to one per day
    crabCellEffect = 4.0,
    --Or two per day at max depth
    crabRateWaterEffect = 2.0,
    maxWaterDepth = 200,
    interval = 0.5,
    --At max skill, max depth, crab cell = catch 4 per day
    skillEffect = 2.0,--at 100
    skillProgress = 2,
}

crabpotConfig.miscToActiveMap = {
    ashfall_crabpot_01_m = "ashfall_crabpot_01_a",
}
crabpotConfig.activeToMiscMap = {}
for misc, active in pairs(crabpotConfig.miscToActiveMap) do
    crabpotConfig.activeToMiscMap[active] = misc
end

local function getActiveFromMisc(miscRef)
    return crabpotConfig.miscToActiveMap[miscRef.object.id:lower()]
end

local function getMiscFromActive(activeRef)
    return crabpotConfig.activeToMiscMap[activeRef.object.id:lower()]
end

event.trigger("Ashfall:RegisterReferenceController", {
    id = "crabpot",
    requirements = function(_, ref)
        return getMiscFromActive(ref)
    end
})

local function playCrabSound(ref)
    common.log:debug("playing a crab sound")
    local crabSounds = {
        "mudcrab roar",
        "mudcrab scream",
        "mudcrab moan"
    }
    local thisSound = table.choice(crabSounds)
    tes3.playSound{ reference = ref, sound = thisSound, pitch = 1.4 }
end

local function updateSwitchNodes(ref)
    local crabCount = math.floor(ref.data.crabCount)
    local crabSwitches = ref.sceneNode:getObjectByName("CRAB_SWITCHES")
    for _, crabSwitch in ipairs(crabSwitches.children) do
        local name = crabSwitch.name
        local num = tonumber(string.sub(name, string.find(name, '=')+1))
        common.log:trace("switch num: %s", num)
        if crabCount >= num then
            crabSwitch.switchIndex = 1
        else
            crabSwitch.switchIndex = 0
        end
    end
end

local function collectCrabs(ref)
    if ref.data.crabCount and ref.data.crabCount >= 1 then
        local count = math.floor(ref.data.crabCount)
        local crabmeat = tes3.getObject("ingred_crab_meat_01")---@type tes3ingredient
        tes3.addItem{ reference = tes3.player, item = crabmeat, count = count }
        tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, count, crabmeat.name)
        ref.data.crabCount = 0
        updateSwitchNodes(ref)
        playCrabSound(ref)
        --progress survival skill for each crab collected
        common.skills.survival:progressSkill(crabpotConfig.skillProgress * count)
    end
end

local function pickup(ref)
    local itemList = {}
    local miscId = getMiscFromActive(ref)
    if not miscId then return end
    collectCrabs(ref)
    tes3.addItem{ reference = tes3.player, item = miscId, }
    common.helper.yeet(ref)
end


--[[
    Check status of pot, pick up, collect crabs or do nothing
]]
local function onActivate(e)
    if e.activator ~= tes3.player then return end
    local ref = e.target
    local miscId = getMiscFromActive(ref)
    if not miscId then return end 
    if tes3ui.menuMode() then
        pickup()
        return false
    end
    local underwater = common.helper.getRefUnderwater(ref)
    if not underwater then
        pickup(ref)
        return false
    end
    if tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode) then
        common.log:debug("Shift activating")
        collectCrabs(ref)
        return
    end
    local crabCount = e.target.data.crabCount and math.floor(e.target.data.crabCount) or 0
    local message = string.format("%s (%d/%d)",e.target.object.name, crabCount, crabpotConfig.maxCrabs)

    common.helper.messageBox{
        message = message,
        buttons = {
            {
                text = "Collect",
                requirements = function()
                    return ref.data.crabCount ~= nil 
                        and ref.data.crabCount >= 1
                end,
                tooltipDisabled = {
                    text = "The Crab Pot is empty."
                },
                callback = function()
                    timer.delayOneFrame(function()
                        collectCrabs(ref)
                    end)
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    pickup(ref)
                end
            },
        },
        doesCancel = true
    }
    return false
end
event.register("activate", onActivate)

local function cellHasCrabs(crabpot)
    for ref in crabpot.cell:iterateReferences(tes3.objectType.creature) do
        if string.find(ref.baseObject.id:lower(), "mudcrab") then
            common.log:debug("Cell has a mudcrab")
            return true
        end
    end
    return false
end

local function initPotData(crabpot)
    crabpot.data.crabCount = 0
    crabpot.data.inCrabCell = cellHasCrabs(crabpot)
end

local function onGearDropped(e)
    local activePotId = getActiveFromMisc(e.reference)
    if activePotId and common.helper.getRefUnderwater(e.reference) then
        local position = e.reference.position:copy()
        local orientation = e.reference.orientation:copy()
        local crabpot = tes3.createReference{
            object = activePotId,
            position = position,
            orientation = orientation,
            cell = e.reference.cell,
        }
        initPotData(crabpot)
        if common.helper.isStack(e.reference) then
            tes3.addItem{
                reference = tes3.player, 
                item = e.reference.object, 
                count = e.reference.attachments.variables.count - 1,
                playSound = false
            }
        end
        common.helper.yeet(e.reference)
    end
end
event.register("Ashfall:GearDropped", onGearDropped)



--Update Crabpot status regularly
local function updatePots(e)

    local function doUpdate(crabPotRef)
        crabPotRef.data.crabCount = crabPotRef.data.crabCount or 0
        crabPotRef.data.lastCrabUpdated = crabPotRef.data.lastCrabUpdated or e.timestamp
        local interval = math.max(e.timestamp - crabPotRef.data.lastCrabUpdated, 0)
        if interval < crabpotConfig.interval then return end

        local underwater = common.helper.getRefUnderwater(crabPotRef)
        local previousCrabCount = math.floor(crabPotRef.data.crabCount)
        if underwater and crabPotRef.data.crabCount < crabpotConfig.maxCrabs then

            --catch more crabs in deeper water
            local waterDepth = math.min(common.helper.getDepthUnderwater(crabPotRef), crabpotConfig.maxWaterDepth)
            local waterEffect = math.remap(waterDepth, 0, crabpotConfig.maxWaterDepth, 1, crabpotConfig.crabRateWaterEffect)
            
            --catch more crabs in cells where mudcrabs are present
            local crabCellEffect = crabPotRef.data.inCrabCell and crabpotConfig.crabCellEffect or 1.0

            --catch more crabs with higher survival skill
            local survivalValue = math.clamp(common.skills.survival.value, 0, 100)
            local skillEffect = math.remap(survivalValue, 0, 100, 1.0, crabpotConfig.skillEffect)

            --Add some random variation
            local maxV = 1 + crabpotConfig.variance
            local minV = 1 - crabpotConfig.variance
            local variance = math.remap(math.random(), 0, 1, minV, maxV) --e.g. between 0.8 and 1.2 if crabpotConfig.variance is 0.2

            --add multipliers together
            local perHourIncrease = crabpotConfig.crabsPerHour * waterEffect * crabCellEffect * skillEffect * variance
            --Scale to how much time has passed
            local increase = perHourIncrease * interval

            --update count on ref
            crabPotRef.data.crabCount = math.clamp(crabPotRef.data.crabCount + increase, 0, crabpotConfig.maxCrabs)

            local currentCrabCount = math.floor(crabPotRef.data.crabCount)
            if currentCrabCount ~= previousCrabCount then
                common.log:debug("previousCrabCount = %s", previousCrabCount)
                common.log:debug("currentCrabCount = %s", currentCrabCount)
                common.log:debug("interval: %.4f", interval)
                common.log:debug("crabCellEffect: %.4f", crabCellEffect)
                common.log:debug("skillEffect: %.4f", skillEffect)
                common.log:debug("waterDepth: %.4f", waterDepth)
                common.log:debug("waterEffect: %.4f", waterEffect)
                common.log:debug("perHourIncrease = %.4f", perHourIncrease)
                common.log:debug("increase = %s\n", increase)
                common.log:debug("New crab count: %s", crabPotRef.data.crabCount)
                playCrabSound(crabPotRef)
                updateSwitchNodes(crabPotRef)
            end
            
            crabPotRef.data.lastCrabUpdated = e.timestamp
        end
    end
    common.helper.iterateRefType("crabpot", doUpdate)
end
event.register("simulate", updatePots)

local function updateTooltip(e)
    local isPot = crabpotConfig.activeToMiscMap[e.object.id:lower()]
    if isPot and e.reference and common.helper.getRefUnderwater(e.reference) then
        local label = e.tooltip:findChild(tes3ui.registerID('HelpMenu_name'))
        if label then
            local crabCount = e.reference.data.crabCount and math.floor(e.reference.data.crabCount) or 0
            label.text = string.format("%s (%d/%d",
                label.text, crabCount, crabpotConfig.maxCrabs
            )
        end
    end
end
event.register("uiObjectTooltip", updateTooltip)