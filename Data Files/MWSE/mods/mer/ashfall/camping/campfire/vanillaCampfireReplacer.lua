local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local campfireConfig = common.staticConfigs.campfireConfig
local randomStuffChances = {
    utensil = 0.4,
    water = 0.6,
    tea = 0.7,
    stew = 0.7
}


local vanillaCampfires = {
    --Ugly ones
    light_pitfire00 =  { supports = false, scale = 0.9},  
    light_pitfire01 =  { supports = false, scale = 0.9 },

    --unlit supports
    furn_de_firepit =  { supports = true },
    furn_de_firepit_01 =  { supports = false },

    --Supports
    furn_de_firepit_f =  { supports = true },
    furn_de_firepit_f_128 = { supports = true },
    furn_de_firepit_f_200 = { supports = true },
    furn_de_firepit_f_323 = { supports = true },
    furn_de_firepit_f_400 = { supports = true },

    --No Supports
    furn_de_firepit_f_01 = { supports = false },
    furn_de_firepit_f_01_400 = { supports = false },
    
}

--A list of shit that campfires can be composed of
--When replacing a vanilla mesh, get rid of these
local kitBashObjects = {
    furn_log_01 = true,
    furn_log_02 = true,
    furn_log_03 = true,
    furn_log_04 = true,
    misc_com_wood_spoon_02 = true,
    misc_com_iron_ladle = true,
    dark_64 = true,
    t_de_var_logpileweathered_01 = true,
    furn_coals_hot = true,
    furn_de_shack_hook = true,
    chimney_smoke_small = true,
}

local cauldrons = {
    furn_com_cauldron_01 = true,
    furn_com_cauldron_02 = true,
    misc_com_bucket_metal = true,
    pot_01 = true
}
local grills = {
    furn_de_minercave_grill_01 = true,
}


--Meshes that a campfire might be sitting on, 
--In which case we don't want to orient it
--Still call orients but maxSteepness 0
local platforms = {
    in_t_platform_02 = true,
    ex_t_rock_coastal_01 = true,
    furn_firepit00 = true,
    in_redoran_ashpit_01 = true,
    furn_de_forge_01 = true
}

local lightPatterns = {
    "light_fire",
    "light_logpile",
    "flame light"
}


local function attachRandomStuff(campfire)
    if string.find(campfire.cell.id:lower(), "tomb") then return end
    if campfire.data.staticCampfireInitialised then return end

    common.log:debug("Attaching random stuff")
    campfire.data.staticCampfireInitialised = true


    --Initialise static utensils
    if campfire.data.dynamicConfig.supports == "static" then
        common.log:debug("Setting hasSupports to true")
        campfire.data.hasSupports = true
    end
    if campfire.data.dynamicConfig.kettle == "static" then
        campfire.data.utensil = "kettle"
    end
    if campfire.data.dynamicConfig.cookingPot == "static" then
        campfire.data.utensil = "cookingPot"
    end
    if campfire.data.dynamicConfig.grill == "static" then
        campfire.data.hasGrill = true
        campfire.data.grillMinHeight =  0
        campfire.data.grillMaxHeight = 100
        campfire.data.grillDistance = 40
    end

    --If supports, add utensils
    if campfire.data.hasSupports then
        if campfire.data.utensil == nil and math.random() < randomStuffChances.utensil then
            campfire.data.utensil = table.choice{ "kettle", "cookingPot"}
            if math.random() < randomStuffChances.water then
                campfire.data.waterAmount = 10 + math.random(50)
                if campfire.data.isLit then
                    campfire.data.waterHeat = campfire.data.isLit and 100 or 0
                    tes3.playSound{
                        reference = campfire, 
                        sound = "ashfall_boil",
                        loop = true
                    }
                end
                --add tea to kettleswaterHeat
                if campfire.data.utensil == "kettle" then
                    if math.random() < randomStuffChances.tea then
                        local teaType = table.choice(common.staticConfigs.teaConfig.validTeas)
                        campfire.data.waterType = teaType
                        campfire.data.teaProgress = 100
                    end
                --add random stew to cooking pots
                elseif campfire.data.utensil == "cookingPot" then
                    if math.random() < randomStuffChances.stew then
                        campfire.data.stewLevels = {}
                        local stewTypes = {}
                        for stewType, _ in pairs(foodConfig.getStewBuffList()) do
                            table.insert(stewTypes, stewType)
                        end
                        local thisStewType = table.choice(stewTypes)
                        campfire.data.stewLevels = {
                            [thisStewType] = 10 + math.random(90)
                        }
                        campfire.data.stewProgress = 100
                    end
                end
            end
        end
    end

    common.log:debug("setting static fuel level")
    campfire.data.fuelLevel = 2 + math.random(3)
end

--If vanilla mesh was a light, then it should be lit by default
local function setInitialState(campfire, vanillaRef, data, hasSupports)

    if hasSupports == true then
        common.log:debug("setting dynamicConfig.supports to static")
        --prevent removal of supports for kitbashing reasons
        campfire.data.dynamicConfig.supports = "static"
        if data.hasCookingPot then
            campfire.data.utensil = "cookingPot"
        end
    elseif data.hasPlatform == true then
       campfire.data.dynamicConfig.supports = "none"
    end

    --fire is lit already?
    local doLight = (
        data.isLit or
        vanillaRef.object.objectType == tes3.objectType.light
    )
    common.log:debug("Campfire initial fireState: %s", (doLight and "lit" or "unlit") )
    if doLight then
        campfire.data.isLit = true
        common.log:debug("Playing Fire sound on %s", campfire.object.id)
        tes3.playSound{ sound = "Fire", reference = campfire, loop = true }
    else
        campfire:deleteDynamicLightAttachment()
    end
end

local function getCloseEnough(e)
    local pos1 = tes3vector3.new(e.ref1.position.x, e.ref1.position.y, 0)
    local pos2 = tes3vector3.new(e.ref2.position.x, e.ref2.position.y, 0)
    local distHorizontal = pos1:distance(pos2)
    local distVertical = math.abs(e.ref1.position.z - e.ref2.position.z)
    return (distHorizontal < e.distHorizontal and distVertical < e.distVertical)
end


--[[
    Finds nearby objects that might make up a campfire, 
    disables them and determines the replacement campfire
    based on what was found
]]
local function checkKitBashObjects(vanillaRef)
    common.log:debug("Checking kit bash objects for %s", vanillaRef.object.id)
    local hasGrill = false
    local hasCookingPot = false
    local hasPlatform = false
    local isLit = false
    local ignoreList = {}
    for ref in vanillaRef.cell:iterateReferences() do
        local id = ref.object.id:lower()
        
        if getCloseEnough({ref1 = ref, ref2 = vanillaRef, distHorizontal = 75, distVertical = 200}) then
            
            common.log:debug("Nearby ref: %s", ref.object.id)

            if ref ~= vanillaRef then
                --don't mess with campfires that have unique things nearby
                if string.find(id, "_unique") then
                    common.log:debug("Found a unique mesh, ignoring campfire replacement")
                    return false
                end

                if platforms[id] then
                    common.log:debug("Has platform")
                    hasPlatform = true
                end
                
                --if you find an existing campfire, get rid of it
                if campfireConfig.getConfig(id) then
                    common.log:debug("Found replaced campfire")
                    common.helper.yeet(ref)
                end
                
                if cauldrons[id] then
                    hasCookingPot = true
                    common.helper.yeet(ref)
                end
                if grills[id] then
                    hasGrill = true
                    common.helper.yeet(ref)
                end
                if kitBashObjects[id] then      
                    common.helper.yeet(ref)
                    table.insert(ignoreList, ref)
                end

                for _, pattern in ipairs(lightPatterns) do
                    if string.startswith(id, pattern)then
                        common.log:debug("Found a fire")
                        isLit = true
                        common.helper.yeet(ref)
                    end
                end
            end
        end
    end
    return {ignoreList = ignoreList, hasGrill = hasGrill, hasCookingPot = hasCookingPot, hasPlatform = hasPlatform, isLit = isLit}
end



local function replaceCampfire(e)
    --local safeRef = tes3.makeSafeObjectHandle(e.reference)
    event.register("simulate", function()
        
        --if not safeRef:valid() then return end
        if e.reference.disabled or e.reference.deleted then return end
        local vanillaConfig = vanillaCampfires[e.reference.object.id:lower()]
        local campfireReplaced = e.reference.data and e.reference.data.campfireReplaced
        if vanillaConfig and not campfireReplaced then
            e.reference.data.campfireReplaced = true
            --decide which campfire to replace with
            local data = checkKitBashObjects(e.reference)
            if not data then return end
            local replacement = "ashfall_campfire_static"
            if data.hasGrill then
                common.log:debug("Has Grill")
                replacement = "ashfall_campfire_grill"
            elseif vanillaConfig.supports == true then
                replacement = "ashfall_campfire_static"
            elseif data.hasCookingPot then
                common.log:debug("Has Pot, no supports")
                replacement = "ashfall_campfire_sup"
            else
                replacement = "ashfall_campfire_static"
            end

            common.log:debug("\n\nREPLACING %s with %s", e.reference.object.id, replacement)
            common.log:debug("position %s", e.reference.position)
            common.log:debug("hasPlatform %s", data.hasPlatform)

            local campfire = tes3.createReference{
                object = replacement,
                position = e.reference.position:copy(),
                orientation = {
                    e.reference.orientation.x,
                    e.reference.orientation.y,
                    tes3.player.orientation.z
                },
                cell = e.reference.cell
            }

            campfire.data.dynamicConfig = campfireConfig.getConfig(replacement)
            
            setInitialState(campfire, e.reference, data, vanillaConfig.supports)
            attachRandomStuff(campfire)

            campfire.scale = e.reference.scale
            if vanillaConfig.scale then
                campfire.scale = campfire.scale * vanillaConfig.scale
            end
            --For stuff inside platforms, let the scale get smaller
            local minScale = data.hasPlatform and 0.6 or 0.75
            campfire.scale = math.clamp(campfire.scale, minScale, 1.3)
            common.log:debug("setting scale to %s", campfire.scale)

            table.insert(data.ignoreList, campfire)
            e.reference:disable()
            common.helper.yeet(e.reference)

            common.helper.orientRefToGround{ 
                ref = campfire, 
                maxSteepness = (data.hasPlatform and 0.0 or 0.2),
                ignoreList = data.ignoreList
            }
            common.log:debug("Campfire final supports: %s\n\n", campfire.data.dynamicConfig.supports)

        end
    end,{ doOnce = true })
end
--event.register("referenceSceneNodeCreated", replaceCampfire)


local function replaceCampfires(e)
        for ref in e.cell:iterateReferences() do
            replaceCampfire{reference = ref}
        end
end
event.register("cellChanged", replaceCampfires)
