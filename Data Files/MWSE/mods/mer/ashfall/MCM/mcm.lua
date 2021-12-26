local common = require("mer.ashfall.common.common")
local versionController = require("mer.ashfall.versionController")

local config = require("mer.ashfall.config.config").config


local function createTableVar(id)
    return mwse.mcm.createTableVariable{ id = id, table = config }
end

local sideBarDefault =
[[Use the configuration menu to turn various mechanics, features and update messages on or off.

Hover over individual settings to see more information.]]

local function postFormat(self)
    self.elements.outerContainer.borderAllSides = self.indent
    self.elements.outerContainer.alignY = 1.0
    --self.elements.outerContainer.layoutHeightFraction = 1.0
    if self.elements.info then
        self.elements.info.layoutOriginFractionX = 0.5
    end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Ashfall", headerImagePath = "textures/ashfall/MCMHeader.tga" }
    template.onClose = function()
        config.save()
    end
    template:register()

    local function addSideBar(component)
        local versionText = string.format("Ashfall Version %s", versionController.getVersion())
        local summaryCategory = component.sidebar:createCategory(versionText)
        component.sidebar:createInfo{ text = sideBarDefault}

        local linksCategory = component.sidebar:createCategory("Links")
        linksCategory:createHyperLink{
            text = "Release history",
            url = "https://github.com/jhaakma/ashfall/releases"
        }
        linksCategory:createHyperLink{
            text = "Wiki",
            url = "https://github.com/jhaakma/ashfall/wiki"
        }
        linksCategory:createHyperLink{
            text = "Nexus",
            url = "https://www.nexusmods.com/morrowind/mods/49057"
        }
        linksCategory:createHyperLink{
            text = "Buy me a coffee",
            url = "https://ko-fi.com/merlord"
        }


        local creditsCategory = component.sidebar:createCategory("Credits")


        creditsCategory:createHyperLink{
            text = "Made by Merlord",
            url = "https://www.nexusmods.com/users/3040468?tab=user+files",
            --postCreate = postFormat,
        }

        creditsCategory:createHyperLink{
            text = "Graphic Design by XeroFoxx",
            url = "https://www.youtube.com/channel/UCcx5oYt3NtLtadZTSjI3KEw",
            --postCreate = postFormat,
        }

        creditsCategory:createHyperLink{
            text = "Tent Covers by Draconik",
            url = "https://www.nexusmods.com/morrowind/users/86600168",
            --postCreate = postFormat,
        }

        creditsCategory:createHyperLink{
            text = "Dream Catcher mesh by Remiros",
            url = "https://www.nexusmods.com/morrowind/users/899234",
            --postCreate = postFormat,
        }

        creditsCategory:createHyperLink{
            text = "Sitting/sleeping animations by Vidi Aquam",
            url = "https://www.nexusmods.com/morrowind/mods/48782",
            --postCreate = postFormat,
        }
    end

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
                variable = createTableVar("overrideTimeScale"),
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
                variable = createTableVar("manualTimeScale"),
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
                variable = createTableVar("enableTemperatureEffects"),
            }
            categorySurvival:createYesNoButton{
                label = "Enable Hunger",
                description = (
                    "When enabled, you must eat food regularly in order to survive. " ..
                    "Ingredients provide a small amount of nutritional value, but you can also cook meals at campfires, cooking pots and stoves. "
                ),
                variable = createTableVar("enableHunger"),
            }
            categorySurvival:createYesNoButton{
                label = "Enable Thirst",
                description = (
                    "When enabled, you must drink water regularly in order to survive " ..
                    "Fill bottles with water at any nearby stream, well or keg. You can also drink directly from water sources."
                ),
                variable = createTableVar("enableThirst"),
                callback = tes3ui.updateInventoryTiles --to clear water bottle icons
            }
            categorySurvival:createYesNoButton{
                label = "Enable Sleep",
                description = (
                    "When enabled, you must sleep regularly or face debuffs from tiredness deprivation. " ..
                    "Sleeping in a bed or bedroll will allow you to become \"Well Rested\", while sleeping out in the open will not fully recover your tiredness."
                ),
                variable = createTableVar("enableTiredness"),
            }
            categorySurvival:createYesNoButton{
                label = "Enable Blight",
                description = "When enabled, you can catch the blight from blight storms. Disable this for compatibility with other blight mods.",
                variable = createTableVar("enableBlight"),
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
                variable = createTableVar("showTemp"),
            }
            categoryConditions:createOnOffButton{
                label = "Hunger updates",
                description = "Show update messages when hunger condition changes.",
                variable = createTableVar("showHunger"),
            }
            categoryConditions:createOnOffButton{
                label = "Thirst updates",
                description = "Show update messages when thirst condition changes.",
                variable = createTableVar("showThirst"),
            }
            categoryConditions:createOnOffButton{
                label = "Sleep updates",
                description = "Show update messages when tiredness condition changes.",
                variable = createTableVar("showTiredness"),
            }
            categoryConditions:createOnOffButton{
                label = "Wetness updates",
                description = "Show update messages when wetness condition changes.",
                variable = createTableVar("showWetness"),
            }
        end --\Condition Updates Category

        do --Miscellanious Category

            local categoryMisc = pageGeneral:createCategory{
                label = "Miscellanious",
                description = "Ashfall features not directly related to survival mechanics.",
            }

            categoryMisc:createKeyBinder{
                label = "Assign Modifier Hotkey",
                description = "Key Modifier for accessing special options. For example, hold down this key while activating a water bottle to open the water menu (to empty or drink from the bottle directly). Default: Left Shift.",
                allowCombinations = false,
                variable = createTableVar("modifierHotKey"),
            }

            categoryMisc:createYesNoButton{
                label = "Start New Games with Survival Gear",
                description = "Start new games with a wood axe, bedroll and cooking pot.",
                variable = createTableVar("startingEquipment")
            }

            categoryMisc:createYesNoButton{
                label = "Hunger/Thirst can Kill",
                description = (
                    "When enabled, you can die of hunger or thirst. Otherwise you will drop to 1 health."
                ),
                variable = createTableVar("needsCanKill"),
            }

            categoryMisc:createYesNoButton{
                label = "Enable Dynamic Branch Placement",
                description = "Loose branches will spawn near trees, which can be picked up for firewood. May cause a slight delay on cell change on lower end systemss. Disable this if you experience performance issues.",
                variable = createTableVar("enableBranchPlacement")
            }

            categoryMisc:createYesNoButton{
                label = "Enable Frost Breath",
                description = (
                    "Adds a frost breath effect to NPCs and the player in cold temperatures. \n\n" ..
                    "Does not require weather survival mechanics to be active. "
                ),
                variable = createTableVar("showFrostBreath"),
            }

            categoryMisc:createYesNoButton{
                label = "Display Backpacks",
                description = "Disable this to prevent backpacks from being displayed on your back.",
                variable = createTableVar("showBackpacks"),
            }

            categoryMisc:createYesNoButton{
                label = "See-Through Tents",
                description = "When enabled, the outside of your tent will become transparent when you enter it.",
                variable = createTableVar("seeThroughTents")
            }

            categoryMisc:createYesNoButton{
                label = "Atronachs Regain Magicka from Drinking",
                description = "When you get thirsty, your maximum magicka (and, therefore, your current magicka) decreases. By default, recovering from thirst recovers the same amount of current magicka as what was lost from being thirsty, even if you have the Atronach sign. Disable this setting to prevent this magicka gain. Be warned, this means as an Atronach you will need to find ways to recover your magicka after drinking.",
                variable = createTableVar("atronachRecoverMagickaDrinking")
            }

            categoryMisc:createYesNoButton{
                label = "Potions Hydrate",
                description = "When enabled, drinking a potion will provide a small amount of hydration.",
                variable = createTableVar("potionsHydrate")
            }

            categoryMisc:createYesNoButton{
                label = "Harvest Wood in Wilderness Only",
                description = (
                    "If this is enabled, you can not harvest wood with an axe while in town."
                ),
                variable = createTableVar("illegalHarvest"),
            }

            categoryMisc:createYesNoButton{
                label = "Allow Camping in Settlements",
                description = (
                    "If this is enabled, you can make campfires and pitch tents within settlement exteriors."
                ),
                variable = createTableVar("canCampInSettlements"),
            }

            categoryMisc:createYesNoButton{
                label = "Diseased Meat",
                description = (
                    "If this is enabled, meat harvested from diseased or blighted animals can make you sick if you eat it."
                ),
                variable = createTableVar("enableDiseasedMeat"),
            }


        end --\Miscellanious Category

    end -- \General Settings Page

    do --Mod values page
        local pageModValues = template:createSideBarPage{
            label = "Mod Values"
        }
        addSideBar(pageModValues)
        pageModValues.noScroll = true
        -- do --Time Category
        --     local categoryTime = pageModValues:createCategory{
        --         label = "Time",
        --         description = "Change time components."
        --     }

        --     -- categoryTime:createSlider{
        --     --     label = "Time Scale",
        --     --     description = ("Changes the speed of the day/night cycle. A value of 1 makes the day go at real-time speed; "
        --     --     .."an in-game day would last 24 hours in real life. A value of 10 will make it ten times as fast as real-time "
        --     --     .."(i.e., one in-game day lasts 2.4 hours), etc. "
        --     --     .."\n\nThe default timescale is 30 (1 in-game day = 48 real minutes), however a value of 15-25 is highly recommended."),
        --     --     min = 0,
        --     --     max = 50,
        --     --     step = 1,
        --     --     jump = 5,
        --     --     variable = mwse.mcm:createGlobal{ id = "timeScale"}
        --     -- }
        -- end --\Time category

        do --Hunger Category
            local categoryTime = pageModValues:createCategory{
                label = "Hunger",
                description = "Change hunger components.",
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
                variable = createTableVar("hungerRate"),
            }
        end --\Hunger category

        do --Thirst Category
            local categoryThirst = pageModValues:createCategory{
                label = "Thirst",
                description = "Change thirst components.",
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
                variable = createTableVar("thirstRate"),
            }
        end--\Thirst Category

        do --Sleep Category
            local categorySleep = pageModValues:createCategory{
                label = "Sleep",
                description =  "Change tiredness components."
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
                variable = createTableVar("loseSleepRate"),
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
                variable = createTableVar("loseSleepWaiting"),
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
                variable = createTableVar("gainSleepRate"),
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
                variable = createTableVar("gainSleepBed"),
            }
        end --\Sleep Category

    end --\mod values page

    do --Exclusions Page
        template:createExclusionsPage{
            label = "Food/Drink Blacklist",
            description = (
                "Select which food and drinks will not be counted in thirst/hunger in Ashfall. You can also blacklist entire plugins so all the items they add will not be counted."
            ),
            variable = createTableVar("blocked"),
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
                            if obj.class then
                                local bartersFields = {
                                    "bartersMiscItems",
                                }
                                for _, field in ipairs(bartersFields) do
                                    if obj.class[field] == true then
                                        return true
                                    end
                                end
                            end
                            return false
                        end

                        local merchants = {}
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
                                    if obj.class[field] == true then
                                        return true
                                    end
                                end
                            end
                            return false
                        end

                        local merchants = {}
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
        --get a formatted string of all Ashfall data

        local function addLine(text, line, indent)
            for i = 0, indent, 1 do
                text = text .. " "
            end
            text = string.format("%s%s", text, line)
            return text
        end

        local function recursivePrint()
            if not tes3.player then return "" end
            local data = common.data
            local text = ""
            local indent = 0
            local function recurse(thisData)
                for key, val in pairs(thisData) do

                    if type(val) == "table" then
                        local line = string.format("%s: {\n", key)
                        text = addLine(text, line, indent)
                        indent = indent + 1
                        recurse(val)
                        indent = indent - 1
                        line = "},\n"
                        text = addLine(text, line, indent)

                    else
                        local line = string.format("%s: %s,\n", key, val)
                        text = addLine(text, line, indent)
                    end
                end
            end
            recurse(data)
            return text
        end

        --Add settings for each Ashfall data field each time the menu is opened
        local function postCreateData(self)
            if not tes3.player then return end
            --clear the existing components
            self.elements.subcomponentsContainer:destroyChildren()
            self.components = {}

            local path = "Ashfall"
            local data = common.data
            local function recurse(component)

                --Boolean: buttons
                for key, val in pairs(data) do
                    if type(val) == "boolean" then
                        component:createOnOffButton{
                            label = key,
                            variable = mwse.mcm.createPlayerData {
                                id = key,
                                path = path
                            },
                            getText = function(button)
                                return button.variable.value and "true" or "false"
                            end
                        }
                    end
                end
                --Strings: text fields
                for key, val in pairs(data) do
                    if type(val) == "string" then
                        component:createTextField{
                            label = key,
                            variable = mwse.mcm.createPlayerData {
                                id = key,
                                path = path
                            },
                        }
                    end
                end
                --numbers: number fields
                for key, val in pairs(data) do
                    if type(val) == "number" then
                        component:createTextField{
                            label = key,
                            variable = mwse.mcm.createPlayerData {
                                id = key,
                                path = path
                            },
                            numbersOnly = true
                        }
                    end
                end
                --tables: category, then recurse over the table
                for key, val in pairs(data) do
                    if type(val) == "table" and not string.find(key, "__") then
                        local category = component:createCategory(key)

                        local prevData = data
                        local prevPath = path
                        path = path .. "." .. key
                        data = val
                        recurse(category)
                        data = prevData
                        path = prevPath
                    end
                end
            end
            recurse(self)
            --Render the new components
            self:createSubcomponents(self.elements.subcomponentsContainer, self.components)
        end

        local pageDevOptions = template:createSideBarPage{
            label = "Development Options",
            description = "Tools for debugging etc. Don't touch unless you know what you're doing.",
        }

        pageDevOptions:createOnOffButton{
            label = "Check For Updates",
            description = "When enabled, you will be notified when a new version of Ashfall is available.",
            variable = createTableVar("checkForUpdates"),
            restartRequired = true,
        }

        pageDevOptions:createOnOffButton{
            label = "Enable Bushcrafting (in development)",
            description = "Get a sneak peak at the upcoming bushcrafting mechanics. Equip any item that has 'Crafting Material' in the tooltip to activate the bushcrafting menu.",
            variable = createTableVar("enableBushcrafting")
        }

        pageDevOptions:createYesNoButton{
            label = "Show Config Menu on Startup",
            description = "The next time you load a new or existing game, show the startup config menu. This is mostly for testing, use the General Settings MCM page to adjsut startup settings.",
            variable = createTableVar("doIntro")
        }

        pageDevOptions:createOnOffButton{
            label = "Debug Mode",
            description = "Enable hot-reload of meshes. For debugging only.",
            variable = createTableVar("debugMode")
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
            variable = createTableVar("logLevel"),
            callback = function(self)
                common.log:setLogLevel(self.variable.value)
            end
        }

        -- pageDevOptions:createOnOffButton{
        --     label = "Enable Development Features",
        --     description = "Enable unfinished features currently in development. Not recommended unless you know what you're doing.",
        --     variable = createTableVar("devFeatures")
        -- }

        pageDevOptions:createButton{
            buttonText = "Print data to log",
            description = "Print all Ashfall data to Morrowind/MWSE.log. If you are having issues with Ashfall, recreate the issue in-game, press this button, then send the MWSE.log file to Merlord at the Morrowind Modding Discord channel.",
            callback = function()
                mwse.log("Ashfall Data:")
                mwse.log(json.encode(common.data, { indent = true }))
            end,
            inGameOnly = true
        }

        -- pageDevOptions:createCategory{
        --     label = "Current Values",
        --     description = (
        --         "Dynamic data for Ashfall. Use with caution, " ..
        --         "although the vast majority of these values are " ..
        --         "re-calculated every frame so changing them here won't do much."
        --     ),
        --     postCreate = postCreateData,
        --     inGameOnly = true
        -- }

        -- pageDevOptions:createInfo{
        --     label = "Current Data: ",
        --     inGameOnly = true,
        --     text = "",
        --     postCreate = function(self)
        --         self.elements.info.text = recursivePrint()
        --     end
        -- }
    end --\Dev Options


end

event.register("modConfigReady", registerModConfig)
