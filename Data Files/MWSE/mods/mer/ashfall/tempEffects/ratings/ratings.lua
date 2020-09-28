local this = {}

local common = require("mer.ashfall.common.common")
local ratingsConfig = common.staticConfigs.ratingsConfig

local cache = {
    armor = {},
    clothing = {}
}
local function getCache()
    return cache
    -- common.config.getConfig().warmthCache or {
    --     armor = {},
    --     clothing = {}
    -- }
end 

local function saveCache(newCache) 
    common.config.saveConfigValue("warmthCache", newCache)
end 


function this.isValidArmorSlot( armorSlot )
    return armorSlot ~= tes3.armorSlot.shield
end
function this.isValidClothingSlot( clothingSlot )
    return clothingSlot ~= tes3.clothingSlot.ring and clothingSlot ~= tes3.clothingSlot.amulet and clothingSlot ~= tes3.clothingSlot.belt
end


--[[
    ----------------
    WARMTH
    ----------------

    Every piece of armor or clothing provides some degree of warmth. The raw warmth value is
    either retrieved from the cache, or calculated using name pattern matching to values. 

    Raw warmth values are then multiplied by the coverage of the item. 
]]


--Gets the raw warmth rating of a piece of armor or clothing.
local function getRawItemWarmth(object)
    --get item type
    local type
    if object.objectType == tes3.objectType.armor then
        type = "armor"
    elseif object.objectType == tes3.objectType.clothing then
        type = "clothing"
    else
        common.log:error("Tried to get warmth value of incompatabile item type %s" .. object.objectType )
        return
    end

    local cache = getCache()

    --Find in cache
    if cache[type][object.id] then
        return cache[type][object.id]

    --Not in cache, generate from name and save to cache
    else
        local itemName = string.lower(object.name)
        --String search item names
        for pattern, value in pairs(ratingsConfig.warmth[type].values) do
            if string.find(itemName, string.lower(pattern)) then
                cache[type][object.id] = value
                saveCache(cache)
                return value
            end
        end
    end

    --No pattern found in name, get default value 
    --Don't save to cache in case patterns get added later
    local value
    if object.enchantment then
        value = ratingsConfig.warmth[type].enchanted
    else
        value = ratingsConfig.warmth[type].default
    end

    if not value then
        common.log:error("No warmth value found for %s!", object.name)
        value = 0
    end
    return value
end


--Multiply raw value by number of bodyparts covered
function this.getItemWarmth(object)
    local raw = getRawItemWarmth(object)

    local coverage = this.getItemCoverage(object)

    return raw * coverage
end


--Iterate over all equipped gear and return total warmth

function this.getTotalWarmth()
    local warmth = 0
    --clothing
    for _, slot in pairs(tes3.clothingSlot) do
        local stack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = slot })     
        local validSlot = this.isValidClothingSlot(slot)
        if stack and validSlot then
            warmth = warmth + this.getItemWarmth(stack.object)
        end
    end

    --armor
    for _, slot in pairs(tes3.armorSlot) do
        local stack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = slot })     
        local validSlot = this.isValidArmorSlot(slot)
        if stack and validSlot then
            warmth = warmth + this.getItemWarmth(stack.object)
        end
    end
    local backpack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.armor,
        slot = 11
    }
    if backpack then
        warmth = warmth + this.getItemWarmth(backpack.object)
    end

    return warmth * ratingsConfig.warmth.multiplier
end

function this.getAdjustedWarmth(value)
    return math.floor(value * ( 1 / ratingsConfig.warmth.multiplier ) )
end


--[[
    ---------------------
    COVERAGE
    ---------------------

    Coverage is a measure the percentage of the body is covered by armor or clothing. 
    Coverage is used in the following calculations:
        - How quickly the player gets wet in the rain, or dries off afterwards
        - How quickly the player temperature changes to match that of the environment
        - Coverage of an item acts as a multiplier of its warmth value
    
]]

--Returns a table of bodyParts covered by this item
local function getItemBodyParts(object)
    local mapper
    local slot
    if object.objectType == tes3.objectType.armor then
        slot = tes3.armorSlot
        mapper = ratingsConfig.armorPartMapping
    elseif object.objectType == tes3.objectType.clothing then
        slot = tes3.clothingSlot
        mapper = ratingsConfig.clothingPartMapping
    else
        common.log:error("getItemBodyParts: Not a clothing or armor piece. ")
        return
    end

    if mapper[object.slot] then
        return mapper[object.slot]
    end
end


--Adds up %s for each body part covered by the item
function this.getItemCoverage(object)
    local bodyParts = getItemBodyParts(object)
    if bodyParts then
        local coverage = 0
        for _, part in ipairs(bodyParts) do
            coverage = coverage + ratingsConfig.bodyParts[part]
        end
        return coverage
    end
    return 0
end


function this.getCoveredParts()
    local partsCovered = {
        head = false,
        leftArm = false,
        rightArm = false,
        leftHand = false,
        rightHand = false,
        chest = false,
        legs = false,
        feet = false,
    }
    --clothing
    for _, slot in pairs(tes3.clothingSlot) do
        local stack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = slot })     
        local validSlot = this.isValidClothingSlot(slot)
        if stack and validSlot then
            local parts = getItemBodyParts(stack.object)
            for _, part in ipairs(parts) do
                partsCovered[part] = true
            end
        end
    end

    --armor
    for _, slot in pairs(tes3.armorSlot) do
        local stack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = slot })     
        local validSlot = ( slot ~= tes3.armorSlot.shield )
        if stack and validSlot then
            local parts = getItemBodyParts(stack.object)
            for _, part in ipairs(parts) do
                partsCovered[part] = true
            end
        end
    end

    return partsCovered
end

--Check equipped gear to see which bodyparts are covered and return the % coverage
function this.getTotalCoverage()
    local totalCoverage = 0
    local partsCovered = this.getCoveredParts()

    for part, isCovered in pairs(partsCovered) do
        if isCovered then
            totalCoverage = totalCoverage + ratingsConfig.bodyParts[part] 
        end
    end

    return totalCoverage
end

function this.getAdjustedCoverage(value)
    return math.floor(value * 100)
end

return this
