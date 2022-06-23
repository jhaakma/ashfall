local this = {}
local staticConfigs = require("mer.ashfall.config.staticConfigs")
local config = require("mer.ashfall.config").config
local skillModule = include("OtherSkills.skillModule")
local refController = require("mer.ashfall.referenceController")
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")

--Generic Tooltip with header and description
---@param e AshfallTooltipData
this.createTooltip = require("mer.ashfall.common.tooltip")

--[[
    Returns a human readable timestamp of the given time (or else the current time)
]]
function this.hourToClockTime ( time )
    local gameTime = time or tes3.findGlobal("GameHour").value
    local formattedTime

    local isPM = false
    if gameTime > 12 then
        isPM = true
        gameTime = gameTime - 12
    end


    local hourString = math.floor(gameTime)
    -- if gameTime < 10 then
    --     hourString = string.sub(gameTime, 1, 1)
    -- else
    --     hourString  = string.sub(gameTime, 1, 2)
    -- end

    local minuteTime = ( gameTime - hourString ) * 60
    local minuteString
    if minuteTime < 10 then
        minuteString = "0" .. string.sub( minuteTime, 1, 1 )
    else
        minuteString = string.sub ( minuteTime , 1, 2)
    end

    formattedTime = string.format("%d:%d %s", hourString, minuteString, (isPM and "pm" or "am"))

    return ( formattedTime )
end

function this.getHoursPassed()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end

function this.getIsTraveling()
    return tes3.player.data.Ashfall.playerIsTraveling
end

--[[
    Transfers an amount from the field of one object to that of another
]]
function this.transferQuantity(source, target, sourceField, targetField, amount)
    source[sourceField] = source[sourceField] - amount
    target[targetField] = target[targetField] + amount
end


function this.getInTent()
    return (tes3.player.data.Ashfall.insideTent or tes3.player.data.Ashfall.insideCoveredBedroll)
end

---@param stack tes3reference
---@return number Returns the number remaining in the stack, if any.
---If it removes all from the stack, the reference is deleted, so make sure to check
function this.reduceReferenceStack(stack, count)
    local stackCount = this.getStackCount(stack)
    if stackCount <= count then
        this.yeet(stack)
        return 0
    else
        stack.attachments.variables.count = stack.attachments.variables.count - count
        return stack.attachments.variables.count
    end
end

function this.checkRefSheltered(reference)

    local sheltered = false

    local tent
    reference = reference or tes3.player

    if this.getInside(reference) then
        return true
    end

    local height = reference.object.boundingBox
        and reference.object.boundingBox.max.z or 0

    local results = tes3.rayTest{
        position = {
            reference.position.x,
            reference.position.y,
            reference.position.z + (height/2)
        },
        direction = {0, 0, 1},
        findAll = true,
        maxDistance = 5000,
        ignore = {reference},
        useBackTriangles = true,
    }
    if results then
        for _, result in ipairs(results) do
            if result and result.reference and result.reference.object then
                sheltered =
                    ( result.reference.object.objectType == tes3.objectType.static or
                    result.reference.object.objectType == tes3.objectType.activator ) == true
                if tentConfig.tentActivetoMiscMap[result.reference.object.id:lower()] then
                    --We're covered by a tent, so we are a bit warmer
                    tent = result.reference
                end
                --this looks weird but it makes sense because we don't break out
                --of the for loop if sheletered is false
                if sheltered == true then
                    break
                end
            end
        end
    end
    local safeTent = tes3.makeSafeObjectHandle(tent)
    return sheltered, safeTent
end

function this.getInside(reference)
    reference = reference or tes3.player
    return (
        reference.cell and
        reference.cell.isInterior and
        not reference.cell.behavesAsExterior
    )
end

function this.getRefUnderwater(reference)
    local waterLevel = reference.cell.waterLevel
    if not waterLevel then return false end
    return reference.position.z < waterLevel
end

function this.getDepthUnderwater(reference)
    local waterLevel = reference.cell.waterLevel or 0
    return waterLevel - reference.position.z
end

--TODO: Null needs to fix collision crashes on Disable/Delete
function this.yeet(ref, no)
    if no then
        mwse.error("You called yeet() with a colon, didn't you?")
    end
    ref:disable()
    mwscript.setDelete{ reference = ref}
end



--[[
    Moves the player, designed for short movements
    which probably won't change cell. but if a cell change
    is required, it uses positionCell as a fallback
]]
function this.movePlayer(e)
    --use positionCell if changing cell
    local orientation = e.orientation or tes3.player.orientation:copy()
    if tes3.player.cell ~= e.cell then
        tes3.positionCell{
            reference = tes3.player,
            position = e.position,
            orientation = {
                0,
                0,
                orientation.z
            },
            cell = e.cell,
            teleportCompanions = false
        }
    else -- avoid positionCell because it sucks
        tes3.player.position = e.position
        tes3.player.orientation = orientation
    end

end

function this.isStack(reference)
    return (
        reference.attachments and
        reference.attachments.variables and
        reference.attachments.variables.count > 1
    )
end

function this.getStackCount(reference)
    return reference
        and reference.attachments
        and reference.attachments.variables
        and reference.attachments.variables.count or 1
end


function this.getGenericUtensilName(obj)
    local name = obj and obj.name
    if name then
        local colonIndex = string.find(obj.name, ":") or 0
        return string.sub(obj.name, 0, colonIndex - 1 )
    end
end



--[[
    Checks if two refs are near each other, with
    separate horizontal and vertical distance checks
    params:
        ref1, ref2
        distVertical, distHorizontal
]]
function this.getCloseEnough(e)
    local pos1 = tes3vector3.new(e.ref1.position.x, e.ref1.position.y, 0)
    local pos2 = tes3vector3.new(e.ref2.position.x, e.ref2.position.y, 0)
    local distHorizontal = pos1:distance(pos2)
    local distVertical = math.abs(e.ref1.position.z - e.ref2.position.z)
    return (distHorizontal < e.distHorizontal and distVertical < e.distVertical)
end



function this.addLabelToTooltip(tooltip, labelText, color)
    local function setupOuterBlock(e)
        e.flowDirection = 'left_to_right'
        e.paddingTop = 0
        e.paddingBottom = 2
        e.paddingLeft = 6
        e.paddingRight = 6
        e.autoWidth = true
        e.autoHeight = true
        e.childAlignX = 0.5
    end
    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = tooltip:findChild(partmenuID)
        and tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)
        or tooltip

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)

    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
    if labelText then
        local label = outerBlock:createLabel({text = labelText})
        label.autoHeight = true
        label.autoWidth = true
        label.widthProportional = 1.0
        if color then label.color = color end
        return label
    end
    return outerBlock
end


function this.recoverStats(e)
    local interval = e.interval
    local isResting = e.resting
    local endurance = tes3.mobilePlayer.endurance.base

    local isStunted = tes3.isAffectedBy{ reference = tes3.player, effect = tes3.effect.stuntedMagicka}
    if isResting then
        --health
        do
            local healthRecovery = interval * 0.1 * endurance
            local remaining = math.max(tes3.mobilePlayer.health.base - tes3.mobilePlayer.health.current, 0)
            healthRecovery = math.min(healthRecovery, remaining)
            tes3.modStatistic{ reference = tes3.player, name = "health", current = healthRecovery }
        end

        --magicka
        if not isStunted then
            local intelligence = tes3.mobilePlayer.intelligence.base
            local fRestMagicMult = tes3.findGMST(tes3.gmst.fRestMagicMult).value
            local magickaRecovery = fRestMagicMult * intelligence * interval
            local remaining = math.max(tes3.mobilePlayer.magicka.base - tes3.mobilePlayer.magicka.current, 0)
            magickaRecovery = math.min(magickaRecovery, remaining)
            tes3.modStatistic{ reference = tes3.player, name = "magicka", current = magickaRecovery }
        end
    end

    --fatigue
    local fFatigueReturnBase = tes3.findGMST(tes3.gmst.fFatigueReturnBase).value
    local fFatigueReturnMult = tes3.findGMST(tes3.gmst.fFatigueReturnMult).value
    local fEndFatigueMult = tes3.findGMST(tes3.gmst.fEndFatigueMult).value
    local normalisedEndurance = math.clamp(endurance/100, 0.0, 1.0)
    local fatigueRecoveryBase = fFatigueReturnBase + fFatigueReturnMult * ( 1 - normalisedEndurance)
    local fatigueRecovery = fatigueRecoveryBase * fEndFatigueMult * endurance * interval * 60
    local remaining = math.max(tes3.mobilePlayer.fatigue.base - tes3.mobilePlayer.fatigue.current, 0)
    fatigueRecovery = math.min(fatigueRecovery, remaining)
    tes3.modStatistic{ reference = tes3.player, name = "fatigue", current = fatigueRecovery }
end

function this.getIsSleeping()
    return tes3.mobilePlayer.sleeping or tes3.player.data.Ashfall.isSleeping
end
function this.getIsWaiting()
    return tes3.mobilePlayer.waiting or tes3.player.data.Ashfall.isWaiting
end

function this.getCollisionNode(rootNode)
    for node in table.traverse{rootNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            return node
        end
    end
end

function this.togglePlayerCollision(collisionState)
    tes3.mobilePlayer.mobToMobCollision = collisionState
    tes3.mobilePlayer.movementCollision = collisionState
end

--[[
    Create a popup with a slider that sets a table value
]]
local menuId = tes3ui.registerID("Ashfall:SliderPopup")
function this.createSliderPopup(params)
    assert(params.label)
    assert(params.varId)
    assert(params.table)
    --[[Optional params:
        jump - slider jump value
        okayCallback - function called on Okay
        cancelCallback - function called on Cancel
    ]]
    local menu = tes3ui.createMenu{ id = menuId, fixedFrame = true }
    tes3ui.enterMenuMode(menuId)
    --Slider
    local sliderBlock = menu:createBlock()
    sliderBlock.width = 500
    sliderBlock.autoHeight = true
    mwse.mcm.createSlider(
        menu,
        {
            label = params.label,
            min = params.min or 0,
            max = params.max or 100,
            jump = params.jump or 10,
            variable = mwse.mcm.createTableVariable{
                id = params.varId,
                table = params.table
            },
        }
    )
    local buttonBlock = menu:createBlock()
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.childAlignX = 1.0
    --Okay
    local okayButton = buttonBlock:createButton{
        text = tes3.findGMST(tes3.gmst.sOK).value
    }
    okayButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
            if params.okayCallback then
                timer.frame.delayOneFrame(params.okayCallback)
            end
        end
    )
    --Cancel
    local cancelButton = buttonBlock:createButton{
        text = tes3.findGMST(tes3.gmst.sCancel).value
    }
    cancelButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
            if params.cancelCallback then
                timer.frame.delayOneFrame(params.cancelCallback)
            end
        end
    )
    menu:getTopLevelMenu():updateLayout()
end

local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
    tes3.mobilePlayer.mouseLookDisabled = state
end
function this.disableControls()
    setControlsDisabled(true)
end

function this.enableControls()
    setControlsDisabled(false)
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end

function this.getUniqueCellId(cell)
    if cell.isInterior then
        return cell.id:lower()
    else
        return string.format("%s (%s,%s)",
        cell.id:lower(),
        cell.gridX,
        cell.gridY)
    end
end

function this.loadMesh(mesh)
    local useCache = not config.debugMode
    return tes3.loadMesh(mesh, useCache):clone()
end

function this.isInnkeeper(reference)
    local obj = reference.baseObject or reference.object
    local objId = obj.id:lower()
    local classId = obj.class and reference.object.class.id:lower()
    return ( classId and staticConfigs.innkeeperClasses[classId])
        or config.foodWaterMerchants[objId]
end

--Returns if an object is blocked by the MCM
function this.getIsBlocked(obj)
    local mod = obj.sourceMod and obj.sourceMod:lower()
    return (
        config.blocked[obj.id] or
        config.blocked[mod]
    )
end

--[[
    Fades out, passes time then runs callback when finished
]]--
function this.fadeTimeOut( hoursPassed, secondsTaken, callback )
    local function fadeTimeIn()
        this.enableControls()
        callback()
        tes3.player.data.Ashfall.fadeBlock = false
    end
    tes3.player.data.Ashfall.fadeBlock = true
    tes3.fadeOut({ duration = 0.5 })
    this.disableControls()
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start({
        type = timer.real,
        iterations = iterations,
        duration = ( secondsTaken / iterations ),
        callback = (
            function()
                local gameHour = tes3.findGlobal("gameHour")
                gameHour.value = gameHour.value + (hoursPassed/iterations)
            end
        )
    })
    --All the way through, fade back in
    timer.start({
        type = timer.real,
        iterations = 1,
        duration = secondsTaken,
        callback = (
            function()
                local fadeBackTime = 1
                tes3.fadeIn({ duration = fadeBackTime })
                timer.start({
                    type = timer.real,
                    iterations = 1,
                    duration = fadeBackTime,
                    callback = fadeTimeIn
                })
            end
        )
    })
end

function this.iterateRefItems(ref)
    local function iterator()
        for _, stack in pairs(ref.object.inventory) do
            local item = stack.object
            local count = stack.count
            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    coroutine.yield(item, data.count, data)
                    count = count - data.count
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(item, count, stack.variables)
            end
        end
    end
    return coroutine.wrap(iterator)
end

--[[
    Restore lost fatigue to prevent collapsing
]]
function this.restoreFatigue()

    local previousFatigue = tes3.mobilePlayer.fatigue.current
    timer.delayOneFrame(function()
        local newFatigue = tes3.mobilePlayer.fatigue.current
        if previousFatigue >= 0 and newFatigue < 0 then
            tes3.mobilePlayer.fatigue.current = previousFatigue
        end
    end)
end

--[[
    Attempt to contract a disease
]]
local defaultChance = 1.0
local maxSurvivalEffect = 0.5
function this.tryContractDisease(spellID)
    local spell = tes3.getObject(spellID)
    local resistDisease = tes3.mobilePlayer.resistCommonDisease
    if spell.castType == tes3.spellType.blight then
        resistDisease = tes3.mobilePlayer.resistBlightDisease
    end

    local survival = skillModule.getSkill("Ashfall:Survival").value
    local resistEffect = math.remap( math.min(resistDisease, 100), 0, 100, 1.0, 0.0 )
    local survivalEffect =  math.remap( math.min(survival, 100), 0, 100, 1.0, maxSurvivalEffect )


    local catchChance = defaultChance * resistEffect * survivalEffect
    local roll= math.random()
    if roll < catchChance then
        if not tes3.player.object.spells:contains(spell) then
            tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicContractDisease).value, spell.name)
            mwscript.addSpell{ reference = tes3.player, spell = spell  }
        end
    end
end

--[[
    Get a number between 0 and 1 based on the current day of the year,
    where 0 is the middle of Winter and 1 is the middle of Summer
]]
local day
local month
function this.getSeasonMultiplier()
    day = day or tes3.worldController.day
    month = month or tes3.worldController.month
    local dayOfYear = day.value + tes3.getCumulativeDaysForMonth(month.value)
    local dayAdjusted = dayOfYear < 196 and dayOfYear  or ( 196 - ( dayOfYear - 196 ) )
    local seasonMultiplier = math.remap(dayAdjusted, 0, 196, 0, 1)
    return seasonMultiplier
end



function this.iterateRefType(refType, callback)
    for ref, _ in pairs(refController.controllers[refType].references) do
        --check requirements in case it's no longer valid
        if refController.controllers[refType]:requirements(ref) then
            if ref.sceneNode then
                callback(ref)
            end
        else
            --no longer valid, remove from ref list
            refController.controllers[refType].references[ref] = nil
        end
    end
end

function this.traverseRoots(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

function this.addDecal(reference, texturePath)
    for node in this.traverseRoots{reference.sceneNode} do
        if node.RTTI.name == "NiTriShape" then
            local texturing_property = node:getProperty(0x4)
            local base_map = texturing_property.maps[3]
            base_map.texture = niSourceTexture.createFromPath(texturePath)
        end
    end
end

local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)

function this.rotationDifference(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return ID33:toEulerXYZ()
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis:normalize()

    local m = ID33:copy()
    m:toRotation(-angle, axis.x, axis.y, axis.z)
    return m:toEulerXYZ()
end

local function log(doLog, message, ...)
    if doLog then
        mwse.log(message, ...)
    end
end
---@return niPickRecord
function this.getGroundBelowRef(e)
    e.doLog = e.doLog or false
    local ref = e.ref
    log(e.doLog, "getGroundBelowRef: %s", ref)

    local ignoreList = e.ignoreList and table.copy(e.ignoreList, {}) or {}
    table.insert(ignoreList, ref)
    table.insert(ignoreList, tes3.player)
    log(e.doLog, "IgnoreList: ")
    for _, ref in ipairs(ignoreList) do
        log(e.doLog, " - %s", ref)
    end
    if not ref then
        log(e.doLog, "getGroundBelowRef: no ref")
        return
    end
    if not ref.object.boundingBox then
        log(e.doLog, "getGroundBelowRef: no bounding box")
        return
    end
    local height = -ref.object.boundingBox.min.z + (e.rootHeight or 5)
    local result = tes3.rayTest{
        position = {ref.position.x, ref.position.y, ref.position.z + height},
        direction = {0, 0, -1},
        ignore = ignoreList or {ref, tes3.player},
        returnNormal = true,
        useBackTriangles = false,
        root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil
    }
    if not result then
        log(e.doLog, "getGroundBelowRef: no result")
        return
    end
    if not result.reference then
        log(e.doLog, "getGroundBelowRef: no reference")
    else
        log(e.doLog, "getGroundBelowRef: %s", result.reference)
    end

    return result
end

function this.getObjectHeight(obj)
    return obj.boundingBox.max.z - obj.boundingBox.min.z
end

function this.getObjectBottomZ(obj)
    return obj.position.z + obj.boundingBox.min.z
end

local function doIgnoreMesh(ref)
    local objType = ref.object.objectType
    if objType == tes3.objectType.static or objType == tes3.objectType.activator then
        return false
    end
    return true
end

---@param ref1 tes3reference
---@param ref2 tes3reference
--[[
    Returns true if the first reference is larger in the X and Y coordinates than the second.
]]
function this.compareReferenceSize(ref1, ref2)
    --initialise bounding boxes from sceneNode
    local bb1 = ref1.object.boundingBox
    local bb2 = ref2.object.boundingBox
    if bb1 and bb2 then
        local ref1Size = bb1.max - bb1.min
        local ref2Size = bb2.max - bb2.min
        return ref1Size.x > ref2Size.x and ref1Size.y > ref2Size.y
    else
        return false
    end
end



function this.orientRefToGround(params)
    local function orientRef(ref, rayResult, maxSteepness)
        local UP = tes3vector3.new(0, 0, 1)
        local newOrientation = this.rotationDifference(UP, rayResult.normal)
        newOrientation.x = math.clamp(newOrientation.x, (0 - maxSteepness), maxSteepness)
        newOrientation.y = math.clamp(newOrientation.y, (0 - maxSteepness), maxSteepness)
        newOrientation.z = ref.orientation.z
        ref.orientation = newOrientation
    end
    local function positionRef(ref, result, maxZ)
        local bb = ref.object.boundingBox
        local offset = params.ignoreBB and 0 or bb.min.z
        if maxZ then
            offset = math.clamp(offset, -maxZ, maxZ)
        end
        ref.position = { ref.position.x, ref.position.y, result.intersection.z - offset }
    end

    local ref = params.ref
    local maxSteepness = params.maxSteepness or 0.4
    local ignoreList = params.ignoreList or {ref, tes3.player}
    local rootHeight = params.rootHeight or 0
    local terrainOnly = params.terrainOnly or false --only look at terrain
    local ignoreNonStatics = params.ignoreNonStatics or false

    if ignoreNonStatics and not terrainOnly then
        for thisRef in ref.cell:iterateReferences() do
            if doIgnoreMesh(thisRef) then
                table.insert(ignoreList, thisRef)
            end
        end
    end

    local result = this.getGroundBelowRef{
        ref = ref,
        ignoreList = ignoreList,
        rootHeight = rootHeight,
        terrainOnly = terrainOnly
    }
    if not result then return false end
    if not params.skipOrient then
        orientRef(ref, result, maxSteepness)
    end
    if not params.skipPosition then
        positionRef(ref, result, params.maxZ)
    end
    return true
end

function this.removeCollision(sceneNode)
    for node in this.traverseRoots{sceneNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end

function this.removeLight(lightNode)

    for node in this.traverseRoots{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        --Kill Melchior's Lantern glow effect
        if  node.name == "LightEffectSwitch" or node.name == "Glow" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        if node.name == "AttachLight" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end

        -- Kill materialProperty
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)

                -- Kill controllers
                materialProperty:removeAllControllers()

                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive

                node:updateProperties()
            end
        end
     -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
        texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
    end
    lightNode:update()
    lightNode:updateNodeEffects()

end


--Cooking functions

--How much water heat affects stew cook speed
function this.calculateWaterHeatEffect(waterHeat)
    return math.remap(waterHeat, staticConfigs.hotWaterHeatValue, 100, 1, 10)
end

function this.calculateStewWarmthBuff(waterHeat)
    return math.remap(waterHeat, staticConfigs.hotWaterHeatValue, 100, 10, 15)
end

--Use survival skill to determine how long a buff should last
function this.calculateStewBuffDuration(waterHeat)
    local waterHeat = waterHeat or 0
    local isCold = waterHeat < staticConfigs.hotWaterHeatValue
    local baseAmount = 8
    local skill = skillModule.getSkill("Ashfall:Survival").value
    local skillEffect = math.remap(skill, 0, 100, 1.0, 2.0)
    local heatEffect = isCold and 0.5 or 1.0
    return baseAmount * skillEffect * heatEffect
end

--Use survival skill to determine how strong a buff should be
function this.calculateStewBuffStrength(value, min, max)
    local effectValue = math.remap(value, 0, 100, min, max)
    local skillEffect = math.remap(skillModule.getSkill("Ashfall:Survival").value, 0, 100, 0.25, 1.0)
    return effectValue * skillEffect
end

--Use survival skill to determine how long a buff should last
function this.calculateTeaBuffDuration(maxDuration, waterHeat)
    local waterHeat = waterHeat or 0
    local isCold = waterHeat < staticConfigs.hotWaterHeatValue
    --Drinking more than limit doesn't increase duration
    --Max survival skill doubles duration
    local survivalSkill = skillModule.getSkill("Ashfall:Survival").value
    local skillMulti =  math.remap(survivalSkill, 0, 100, 1.0, 2.0)
    --Duration is halved if the tea is cold
    local coldEffect = isCold and 0.5 or 1.0
    return maxDuration * skillMulti * coldEffect
end

function this.pickUp(reference, playSound)
    local function stealActivateEvent(e)
        event.unregister("activate", stealActivateEvent)
        e.claim = true
    end

    local function blockSound()
        event.unregister("addSound", blockSound)
        return false
    end

    timer.frame.delayOneFrame(function()
        event.register("activate", stealActivateEvent, { priority = 1000000})
        if not playSound then
            event.register("addSound", blockSound, { priority = 1000000})
        end
        tes3.player:activate(reference)
    end)
end

--Check if there is a heat source below ref
--Based on mesh nodes, can be a fire (which can cook food)
--or a candle (which can warm tea)
function this.getHeatFromBelow(ref, requiredHeatType)
    local ignoreList = {ref}
    --Ignore frying pans
    this.iterateRefType("fryingPan", function(fryingPan)
        table.insert(ignoreList, fryingPan)
    end)
    local result = this.getGroundBelowRef{ ref = ref, ignoreList = ignoreList}
    if not result then return end
    if not result.reference then return end
    local nodes = {
        ATTACH_GRILL = "strong",
        ASHFALL_GRILLER = "strong",
        TEA_WARMER = "weak",
        ASHFALL_FIREBASE = "strong",
    }
    local node = result.object
    local heatType
    while node and node.parent and node.name and heatType == nil do
        heatType = nodes[node.name:upper()]
        node = node.parent
    end

    if heatType then
        if ( not requiredHeatType) or (heatType == requiredHeatType ) then
            return result.reference, heatType
        end
    end
end

function this.isModifierKeyPressed()
    return tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode)
end

function this.getModifierKeyString()
    return this.getLetter(config.modifierHotKey.keyCode)
end

function this.getLetter(keyCode)
    for letter, code in pairs(tes3.scanCode) do
        if code == keyCode then
            local returnString = tes3.scanCodeToNumber[code] or letter
            return string.upper(returnString)
        end
    end
    return nil
end

function this.getComboString(keyCombo)
	-- Returns "SHIFT-X" if shift is held down but the active key is not Shift,
	-- otherwise just "X" (X being the key being pressed)
	-- And so on for Alt and Ctrl

	local letter = this.getLetter(keyCombo.keyCode) or string.format("{%s}", mwse.mcm.i18n("unknown key"))
	local hasAlt = (keyCombo.isAltDown and keyCombo.keyCode ~= tes3.scanCode.lAlt and keyCombo.keyCode ~=
	               tes3.scanCode.rAlt)
	local hasShift = (keyCombo.isShiftDown and keyCombo.keyCode ~= tes3.scanCode.lShift and keyCombo.keyCode ~=
	                 tes3.scanCode.rShift)
	local hasCtrl = (keyCombo.isControlDown and keyCombo.keyCode ~= tes3.scanCode.lCtrl and keyCombo.keyCode ~=
	                tes3.scanCode.rCtrl)
	local prefix = (hasAlt and "Alt-" or hasShift and "Shift-" or hasCtrl and "Ctrl-" or "")
	return (prefix .. letter)
end


function this.showHint(hint)
    if config.showHints then
        return {
            header = "Hint:",
            text = hint
        }
    end
end

function this.playerHasMaterials(materials)
    if not materials then return false end
    local hasMaterials = true
    for mat, count in pairs(materials) do
        if tes3.getItemCount{ reference = tes3.player, item = mat } < count then
            hasMaterials =  false
        end
    end
    return hasMaterials
end

function this.playDeconstructionSound(reference)
    tes3.playSound{
        reference = reference or tes3.player,
        soundPath = "ashfall\\deconstruct.wav"
    }
end

---@param object tes3object|tes3light
function this.isCarryable(object)
    local unCarryableTypes = {
        [tes3.objectType.light] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.static] = true,
        [tes3.objectType.door] = true,
        [tes3.objectType.activator] = true,
        [tes3.objectType.npc] = true,
        [tes3.objectType.creature] = true,
    }
    if object then
        if object.canCarry then
            return true
        end
        local objType = object.objectType
        if unCarryableTypes[objType] then
            return false
        end
        return true
    end
end

return this