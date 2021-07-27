local common = require("mer.ashfall.common.common")
local bugConfig = require("mer.ashfall.items.bugnet.config")


---@param weapon tes3weapon
local function isBugNet(weapon)
    local isNet = bugConfig.bugnets[weapon.id:lower()]
    local attackDirection = tes3.mobilePlayer.actionData.attackDirection
    return isNet and attackDirection == 2
end

---@param reference tes3reference
local function isBug(reference)
    return bugConfig.bugs[reference.baseObject.id:lower()]
end

local function getNearbyBug()
    local eyeOri = tes3.getPlayerEyeVector()
    local eyePos = tes3.getPlayerEyePosition()
    ---A position in front of the player from which to distance check nearby bugs
    local checkPosition = eyePos + eyeOri * bugConfig.checkDistance

    -- tes3.createReference{ 
    --     object = "misc_com_redware_cup",
    --     position = checkPosition,
    --     cell = tes3.player.cell
    -- }
    local closestBug
    local closestDistance = 1000000
    for _, cell in pairs(tes3.getActiveCells()) do
        for container in cell:iterateReferences(tes3.objectType.container) do
            if isBug(container) then
                local bugNode = container.sceneNode:getObjectByName("NightDaySwitch")
                if bugNode then
                    bugNode = bugNode:getObjectByName("ON").children[1].children[1]
                    local distance = checkPosition:distance(bugNode.worldTransform.translation)
                    if distance < bugConfig.maxRadius and distance < closestDistance then
                        common.log:trace("Distance: %s. Required: %d", distance, bugConfig.maxRadius)
                        
                        closestBug = container
                        closestDistance = distance
                    end
                else
                    common.log:trace("Valid bug missing NightDaySwitch")
                end
            end
        end
    end
    common.log:trace("Chosen Bug: %s", closestBug)
    return closestBug
end

---@param bug tes3reference
local function catchBug(bug)
    common.log:trace("Catching bug")
    tes3.player.data.catchingBug = true
    tes3.player:activate(bug)
    tes3.player.data.catchingBug = nil
end

local function onAttack(e)
    common.log:trace("attacking")
    ---@type tes3mobilePlayer
    local mob = e.mobile
    ---@type tes3weapon
    local weapon = mob.readiedWeapon and mob.readiedWeapon.object
    if not weapon then 
        common.log:trace("Not using a weapon")
        return 
    end


    if not isBugNet(weapon) then 
        common.log:trace("Not a bug net")
        return 
    end
    local bug = getNearbyBug()
    if not bug then 
        common.log:trace("No nearby bugs")
        return 
    end
    catchBug(bug)
end
event.register("attack", onAttack )

local function onPickLeveledItem(e)
    if tes3.player.data.catchingBug then
        common.log:trace("Activated while catching bug, manually setting pick")
        tes3.player.data.catchingBug = nil
        ---@type tes3leveledItem
        local list = e.list
        local prevChance = list.chanceForNothing
        list.chanceForNothing = 0
        local newItem = list:pickFrom()
        common.log:trace("Now picking %s", newItem)
        list.chanceForNothing = prevChance
        e.pick = newItem
    end
end
event.register("leveledItemPicked", onPickLeveledItem)