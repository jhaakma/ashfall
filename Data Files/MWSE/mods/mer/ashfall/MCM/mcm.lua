local common = require("mer.ashfall.common.common")
local versionController = require("mer.ashfall.common.versionController")
local config = require("mer.ashfall.config").config

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/ashfall/releases"
    },
    {
        text = "Wiki",
        url = "https://github.com/jhaakma/ashfall/wiki"
    },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/49057"
    },
    {
        text = "Buy me a coffee",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
    {
        text = "Graphic Design by XeroFoxx",
        url = "https://www.youtube.com/channel/UCcx5oYt3NtLtadZTSjI3KEw",
    },
    {
        text = "Tent Covers by Draconik",
        url = "https://www.nexusmods.com/morrowind/users/86600168",
    },
    {
        text = "Dream Catcher mesh by Remiros",
        url = "https://www.nexusmods.com/morrowind/users/899234",
    },
    {
        text = "Sitting/sleeping animations by Vidi Aquam",
        url = "https://www.nexusmods.com/morrowind/mods/48782",
    },
    {
        text = "Glass weapons (and a bunch of other meshes) by Melchior Dahrk",
        url = "https://www.nexusmods.com/morrowind/users/962116"
    },
}
local SIDE_BAR_DEFAULT =
[[Use the configuration menu to turn various mechanics, features and udpate messages on or off.

Hover over individual settings to see more information.]]


local function addSideBar(component)
    local versionText = string.format("Ashfall Version %s", versionController.getVersion())
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = SIDE_BAR_DEFAULT}

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end


local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Ashfall", headerImagePath = "textures/ashfall/MCMHeader.tga" }
    template.onClose = function()
        config.save()
    end
    template:register()
    do --General Settings Page
        local pageGeneral = template:createSideBarPage({
            label = "General Settings",
        })
        addSideBar(pageGeneral)

        do --Default Settings Category
            local categoryOverrides = pageGeneral:createCategory{
                label = "Overrides",
                description = "Set what vanilla values are overriden when you start a new game."
            }
            categoryOverrides:createYesNoButton{
                label = "Override Item Values",
                description = (
                    "Adjusts the weight and value of a few vanilla ingredients such as bread and meat, "..
                    "as well as water containers like bottles and pots, to account for their additional " ..
                    "usefulness in survival mechanics."
                ),
                variable = mwse.mcm.createTableVariable{
                    id = "overrideFood",
                    table = config,
                    restartRequired = true,
                    --restartRequiredMessage = "Changing this setting requires a game restart to come into effect."
                }
            }

            categoryOverrides:createYesNoButton{
                label = "Override TimeScale",
                description = (
                    "This will adjust the timescale on each new game. To adjust the timescale of the "..
                    "current game, toggle this to true and adjust on the slider below."
                ),
                variable = mwse.mcm.createTableVariable{ id = "overrideTimeScale", table = config },
                callback = function(self)
                    if tes3.player then
                        if self.variable.value == true then

                            local newTimeScale = config.manualTimeScale
                            tes3.setGlobal("TimeScale", newTimeScale)
                        end
                    end
                end
            }

            categoryOverrides:createSlider{
                label = "Default Time Scale",
                description = ("Changes the speed of the day/night cycle. A value of 1 makes the day go at real-time speed; "
                .."an in-game day would last 24 hours in real life. A value of 10 will make it ten times as fast as real-time "
                .."(i.e., one in-game day lasts 2.4 hours), etc. "
                .."\n\nThe vanilla timescale is 30 (1 in-game day = 48 real minutes), however a value of 15-25 is highly recommended."),
                min = 0,
                max = 50,
                step = 1,
                jump = 5,
                variable = mwse.mcm.createTableVariable{ id = "manualTimeScale", table = config },
                callback = function(self)
                    if tes3.player then
                        if config.overrideTimeScale == true then
                            tes3.setGlobal("TimeScale", self.variable.value)
                        end
                    end
                end
            }

        end

        do --Survival Mechanics Category
            local categorySurvival = pageGeneral:createCategory{
                label = "Survival Mechanics",
                description = "Turn Ashfall Mechanics on and off."
            }
            categorySurvival:createYesNoButton{
                label = "Enable Temperature & Weather Effects",
                description = (
                    "When enabled, you will need to find shelter from extreme temperatures or face delibitating condition effects. \n\n" ..
                    "At night or in cold climates, stay well fed, wear plenty of clothinug, use torches or firepits or stay indoors to keep yourself warm. \n\n" ..
                    "In hotter climates, make sure you remain hydrated, wear clothing with low warmth ratings and avoid sources of heat like fire, lava or steam. \n\n" ..
                    "Getting wet will cool you down significantly, as well as increase your fire resistance and lower your shock resistance.\n\n"
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableTemperatureEffects", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Enable Hunger",
                description = (
                    "When enabled, you must eat food regularly in order to survive. " ..
                    "Ingredients provide a small amount of nutritional value, but you can also cook meals at campfires, cooking pots and stoves. "
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableHunger", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Enable Thirst",
                description = (
                    "When enabled, you must drink water regularly in order to survive " ..
                    "Fill bottles with water at any nearby stream, well or keg. You can also drink directly from water sources."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableThirst", table = config },
                callback = tes3ui.updateInventoryTiles --to clear water bottle icons
            }
            categorySurvival:createYesNoButton{
                label = "Enable Sleep",
                description = (
                    "When enabled, you must sleep regularly or face debuffs from tiredness deprivation. " ..
                    "Sleeping in a bed or bedroll will allow you to become \"Well Rested\", while sleeping out in the open will not fully recover your tiredness."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableTiredness", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Enable Blight",
                description = "When enabled, you can catch the blight from blight storms. Disable this for compatibility with other blight mods.",
                variable = mwse.mcm.createTableVariable{ id = "enableBlight", table = config },
            }

        end --\Survival Mechanics Category

        do --Condition Updates Category
            local categoryConditions = pageGeneral:createCategory{
                label = "Condition Updates",
                description = "Choose which message updates appear when player conditions change.",
            }

            categoryConditions:createOnOffButton{
                label = "Temperature updates",
                description = "Show update messages when temperature condition changes.",
                variable = mwse.mcm.createTableVariable{ id = "showTemp", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Hunger updates",
                description = "Show update messages when hunger condition changes.",
                variable = mwse.mcm.createTableVariable{ id = "showHunger", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Thirst updates",
                description = "Show update messages when thirst condition changes.",
                variable = mwse.mcm.createTableVariable{ id = "showThirst", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Sleep updates",
                description = "Show update messages when tiredness condition changes.",
                variable = mwse.mcm.createTableVariable{ id = "showTiredness", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Wetness updates",
                description = "Show update messages when wetness condition changes.",
                variable = mwse.mcm.createTableVariable{ id = "showWetness", table = config },
            }
        end --\Condition Updates Category

        do -- Enable Features
            local categoryFeatures = pageGeneral:createCategory{
                label = "Features",
                description = "Enable or disable various features of Ashfall."
            }

            categoryFeatures:createYesNoButton{
                label = "Enable Bushcrafting ",
                description = "To activate the bushcrafting menu, equip any item that has 'Bushcrafting Material' in the tooltip.",
                variable = mwse.mcm.createTableVariable{ id = "bushcraftingEnabled", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Enable Skinning",
                description = "Enable the skinning mechanic. To skin a creature, hack at its corpse with a knife to collect its hide, meat and fur.",
                variable = mwse.mcm.createTableVariable{ id = "enableSkinning", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Enable Dynamic Branch Placement",
                description = "Loose branches will spawn near trees, which can be picked up for firewood. May cause a slight delay on cell change on lower end systemss. Disable this if you experience performance issues.",
                variable = mwse.mcm.createTableVariable{ id = "enableBranchPlacement", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Enable Frost Breath",
                description = (
                    "Adds a frost breath effect to NPCs and the player in cold temperatures. \n\n" ..
                    "Does not require weather survival mechanics to be active. "
                ),
                variable = mwse.mcm.createTableVariable{ id = "showFrostBreath", table = config },
            }

            categoryFeatures:createYesNoButton{
                label = "Animated Tree Felling",
                description = "If this is enabled, trees and vegetation will fall down after you've harvested too many materials from it. They will come back the next time you enter the cell. Realtime shadows and water reflections will not be updated, as this is based on MGE XE distant land statics, which may result in minor visual disparities.",
                variable = mwse.mcm.createTableVariable{ id = "disableHarvested", table = config}
            }

            categoryFeatures:createYesNoButton{
                label = "Enable Diseased Meat",
                description = (
                    "If this is enabled, meat harvested from diseased or blighted animals can make you sick if you eat it."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableDiseasedMeat", table = config },
            }
        end

        do --Miscellanious Category

            local categoryMisc = pageGeneral:createCategory{
                label = "Miscellanious",
                description = "Ashfall settings not directly related to survival mechanics.",
            }

            categoryMisc:createKeyBinder{
                label = "Assign Modifier Hotkey",
                description = "Key Modifier for accessing special options. For example, hold down this key while activating a water bottle to open the water menu (to empty or drink from the bottle directly). Default: Left Shift.",
                allowCombinations = false,
                variable = mwse.mcm.createTableVariable{ id = "modifierHotKey", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Show Hint Tooltips",
                description = "Show additional tooltips explaining various mechanics.",
                variable = mwse.mcm.createTableVariable{ id = "showHints", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Start New Games with Survival Gear",
                description = "Start new games with a wood axe, bedroll and cooking pot.",
                variable = mwse.mcm.createTableVariable{ id = "startingEquipment", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Hunger/Thirst can Kill",
                description = (
                    "When enabled, you can die of hunger or thirst. Otherwise you will drop to 1 health."
                ),
                variable = mwse.mcm.createTableVariable{ id = "needsCanKill", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Display Backpacks",
                description = "Disable this to prevent backpacks from being displayed on your back.",
                variable = mwse.mcm.createTableVariable{ id = "showBackpacks", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "See-Through Tents",
                description = "When enabled, the outside of your tent will become transparent when you enter it.",
                variable = mwse.mcm.createTableVariable{ id = "seeThroughTents", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Atronachs Regain Magicka from Drinking",
                description = "When you get thirsty, your maximum magicka (and, therefore, your current magicka) decreases. By default, recovering from thirst recovers the same amount of current magicka as what was lost from being thirsty, even if you have the Atronach sign. Disable this setting to prevent this magicka gain. Be warned, this means as an Atronach you will need to find ways to recover your magicka after drinking.",
                variable = mwse.mcm.createTableVariable{ id = "atronachRecoverMagickaDrinking", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Potions Hydrate",
                description = "When enabled, drinking a potion will provide a small amount of hydration.",
                variable = mwse.mcm.createTableVariable{ id = "potionsHydrate", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Harvest Wood in Wilderness Only",
                description = (
                    "If this is enabled, you can not harvest wood with an axe while in town."
                ),
                variable = mwse.mcm.createTableVariable{ id = "illegalHarvest", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Allow Camping in Settlements",
                description = (
                    "If this is enabled, you can make campfires and pitch tents within settlement exteriors."
                ),
                variable = mwse.mcm.createTableVariable{ id = "canCampInSettlements", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Allow Resting Outside without a Bed",
                description = (
                    "If this is enabled, you can rest outside on the ground without a bedroll or tent."
                ),
                variable = mwse.mcm.createTableVariable{ id = "canRestOnGround", table = config },
            }

        end --\Miscellanious Category

    end -- \General Settings Page

    do --Mod values page
        local pageModValues = template:createSideBarPage{
            label = "Mod Values"
        }
        addSideBar(pageModValues)

        do -- updates
            local categoryUpdates = pageModValues:createCategory{
                label = "Update Intervals",
                description = "Update intervals for various features.",
            }

            categoryUpdates:createSlider{
                label = "Ray Test Updates (milliseconds)",
                description = "How often ray test dependend updates are triggered. Increasing this may improve performance but will make tooltips etc update less frequently. You must reload your game for this to take effect.",
                min = 10,
                max = 2000,
                step = 10,
                jump = 100,
                variable = mwse.mcm.createTableVariable{ id = "rayTestUpdateMilliseconds", table = config },
            }
        end

        do -- Temperature
            local categoryTemperature = pageModValues:createCategory{
                label = "Temperature",
                description = "Temperature Modifiers.",
            }
            categoryTemperature:createSlider{
                label = "Cold Modifier: %s%%",
                description = string.format("Modifies the intensity of all cold sources."
                    .. "\n\nThe default cold modifier is %s.",
                    common.defaultValues.globalColdEffect
                ),
                min = -50,
                max = 50,
                step = 1,
                variable = mwse.mcm.createTableVariable{ id = "globalColdEffect", table = config },
                callback = function()
                    common.data.globalColdEffect = 1 + config.globalColdEffect * 0.01
                end
            }
            categoryTemperature:createSlider{
                label = "Heat Modifier: %s%%",
                description = string.format("Modifies the intensity of all heat sources."
                    .. "\n\nThe default heat modifier is %s.",
                    common.defaultValues.globalWarmEffect
                ),
                min = -50,
                max = 50,
                step = 1,
                variable = mwse.mcm.createTableVariable{ id = "globalWarmEffect", table = config },
                callback = function()
                    common.data.globalWarmEffect = 1 + config.globalWarmEffect * 0.01
                end
            }
        end
        do --Hunger Category
            local categoryTime = pageModValues:createCategory{
                label = "Hunger",
                description = "Hunger Modifiers.",
            }


            categoryTime:createSlider{
                label = "Hunger Rate",
                description = string.format(
                    "Determines how much hunger you gain per hour. When set to 10, you gain 1%% hunger every hour "
                    .."(not taking into account temperature effects). "
                    .."\n\nThe default hunger rate is %s.",
                    common.defaultValues.hungerRate
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "hungerRate", table = config },
            }
        end --\Hunger category

        do --Thirst Category
            local categoryThirst = pageModValues:createCategory{
                label = "Thirst",
                description = "Thirst Modifiers.",
            }

            categoryThirst:createSlider{
                label = "Thirst Rate",
                description = string.format(
                    "Determines how much thirst you gain per hour. When set to 10, you gain 1%% thirst every hour "
                    .."(not taking into account temperature effects). "
                    .."\n\nThe default thirst rate is %s.",
                    common.defaultValues.thirstRate
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "thirstRate", table = config },
            }
        end--\Thirst Category

        do --Sleep Category
            local categorySleep = pageModValues:createCategory{
                label = "Sleep",
                description =  "Sleep Modifiers.",
            }

            categorySleep:createSlider{
                label = "Tiredness Rate",
                description = string.format(
                    "Determines how much tiredness you gain per hour. When set to 10, you lose 1%% tiredness every hour. "
                    .."\n\nThe default tiredness rate is %s.",
                    common.defaultValues.loseSleepRate
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "loseSleepRate", table = config },
            }
            categorySleep:createSlider{
                label =  "Tiredness Rate (Waiting)",
                description = string.format(
                    "Determines how much tiredness you gain per hour while waiting. When set to 10, you lose 1%% tiredness every hour. "
                    .."\n\nThe default tiredness (waiting) rate is %s.",
                    common.defaultValues.loseSleepWaiting
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "loseSleepWaiting", table = config },
            }

            categorySleep:createSlider{
                label = "Sleep Rate (Ground)",
                description = string.format(
                    "Determines how much tiredness you recover per hour while resting on the ground. "
                    .."When set to 10, you gain 1%% tiredness every hour. "
                    .."\n\nThe default sleep rate (ground) is %s.",
                    common.defaultValues.gainSleepRate
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "gainSleepRate", table = config },
            }
            categorySleep:createSlider{
                label = "Sleep Rate (Bed)",
                description = string.format(
                    "Determines how much tiredness you recover per hour while resting while using a bed. "
                    .."When set to 10, you gain 1%% tiredness every hour. "
                    .."\n\nThe default sleep rate (bed) is %s.",
                    common.defaultValues.gainSleepBed
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "gainSleepBed", table = config },
            }
        end --\Sleep Category

        do --Natural Materials Placement
            local categoryNatualMaterials = pageModValues:createCategory{
                label = "Natural Materials",
                description = "Natural Materials Placement.",
            }

            --Determines frequence of materials such as wood, stone, flint etc that spawn in the world
            categoryNatualMaterials:createSlider{
                label = "Natural Materials Multiplier",
                description = string.format(
                    "Determines how often materials such as wood, stone and flint spawn natrually in the world. "
                    .."\n\nThe default natural materials multiplier is %s.",
                    common.defaultValues.naturalMaterialsMultiplier
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "naturalMaterialsMultiplier", table = config },
            }
        end
    end --\mod values page

    do --Exclusions Page
        template:createExclusionsPage{
            label = "Food/Drink Blacklist",
            description = (
                "Select which food and drinks will not be counted in thirst/hunger in Ashfall. You can also blacklist entire plugins so all the items they add will not be counted."
            ),
            variable = mwse.mcm.createTableVariable{ id = "blocked", table = config },
            filters = {
                {
                    label = "Plugins",
                    type = "Plugin",
                },
                {
                    label = "Food",
                    type = "Object",
                    objectType = tes3.objectType.ingredient,
                },
                {
                    label = "Drinks",
                    type = "Object",
                    objectType = tes3.objectType.alchemy
                }
            }
        }

    end --\Exclusions Page

    local function offersService(npcObject, service)
        if npcObject.class and npcObject.class[service] then
            return true
        end
        if npcObject.aiConfig and npcObject.aiConfig[service] then
            return true
        end
        return false
    end

    do --Camping gear merchants
        template:createExclusionsPage{
            label = "Camping Merchants",
            description = "Move merchants into the left list to allow them to sell camping gear. Changes won't take effect until the next time you enter the cell where the merchant is. Note that removing a merchant from the list won't remove the equipment if you have already visited the cell they are in.",
            variable = mwse.mcm.createTableVariable{ id = "campingMerchants", table = config },
            leftListLabel = "Merchants who sell camping equipment",
            rightListLabel = "Merchants",
            filters = {
                {
                    label = "Merchants",
                    callback = function()
                        --Check if npc is able to sell any guar gear
                        local function canSellGear(obj)
                            local bartersFields = {
                                "bartersMiscItems",
                            }
                            for _, field in ipairs(bartersFields) do
                                if offersService(obj, field) then
                                    return true
                                end
                            end
                            return false
                        end

                        local merchants = {}
                        ---@param obj tes3npcInstance
                        for obj in tes3.iterateObjects(tes3.objectType.npc) do
                            if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                                if canSellGear(obj) then
                                    merchants[#merchants+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                        table.sort(merchants)
                        return merchants
                    end
                }
            }
        }
    end

    do --Camping gear merchants
        template:createExclusionsPage{
            label = "Food/Water Merchants",
            description = "Move merchants into the left list to allow them to sell additional food and offer water refill services. Changes won't take effect until the next time you enter the cell where the merchant is. Note that removing a merchant from the list won't remove the equipment if you have already visited the cell they are in.",
            variable = mwse.mcm.createTableVariable{ id = "foodWaterMerchants", table = config },
            leftListLabel = "Merchants who sell food/refill water",
            rightListLabel = "Merchants",
            filters = {
                {
                    label = "Merchants",
                    callback = function()
                        --Check if npc is able to sell any guar gear
                        local function canSellGear(obj)
                            if obj.class then
                                local bartersFields = {
                                    "bartersAlchemy",
                                    "bartersIngredients"
                                }
                                for _, field in ipairs(bartersFields) do
                                    if offersService(obj, field) then
                                        return true
                                    end
                                end
                            end
                            return false
                        end

                        local merchants = {}
                        ---@param obj tes3npcInstance
                        for obj in tes3.iterateObjects(tes3.objectType.npc) do
                            if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                                if canSellGear(obj) then
                                    merchants[#merchants+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                        table.sort(merchants)
                        return merchants
                    end
                }
            }
        }
    end

    do --Dev Options
        local pageDevOptions = template:createSideBarPage{
            label = "Development Options",
            description = "Tools for debugging etc. Don't touch unless you know what you're doing.",
        }

        pageDevOptions:createOnOffButton{
            label = "Check For Updates",
            description = "When enabled, you will be notified when a new version of Ashfall is available.",
            variable = mwse.mcm.createTableVariable{ id = "checkForUpdates", table = config },
            restartRequired = true,
        }

        pageDevOptions:createYesNoButton{
            label = "Show Config Menu on Startup",
            description = "The next time you load a new or existing game, show the startup config menu. This is mostly for testing, use the General Settings MCM page to adjsut startup settings.",
            variable = mwse.mcm.createTableVariable{ id = "doIntro", table = config }
        }

        pageDevOptions:createOnOffButton{
            label = "Debug Mode",
            description = "Enable hot-reload of meshes. For debugging only.",
            variable = mwse.mcm.createTableVariable{ id = "debugMode", table = config }
        }

        pageDevOptions:createDropdown{
            label = "Log Level",
            description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
            callback = function(self)
                for _, log in ipairs(common.loggers) do
                    log:setLogLevel(self.variable.value)
                end
            end
        }

        pageDevOptions:createButton{
            buttonText = "Print data to log",
            description = "Print all Ashfall data to Morrowind/MWSE.log. If you are having issues with Ashfall, recreate the issue in-game, press this button, then send the MWSE.log file to Merlord at the Morrowind Modding Discord channel.",
            callback = function()
                mwse.log("Ashfall Data:")
                mwse.log(json.encode(common.data, { indent = true }))
            end,
            inGameOnly = true
        }
    end --\Dev Options
end

event.register("modConfigReady", registerModConfig)