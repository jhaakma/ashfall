local CraftingFramework = require("CraftingFramework")
local ClayDeposit = require("mer.ashfall.clay.ClayDeposit")
local DepositActivator = require("mer.ashfall.clay.DepositActivator")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryDecals = require("mer.ashfall.clay.Visuals.PotteryDecals")
local clayConfig = require("mer.ashfall.clay.config")
local FiringController = require("mer.ashfall.clay.FiringController")
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local FiredPottery = require("mer.ashfall.clay.FiredPottery")
local PotteryWheel = require("mer.ashfall.clay.PotteryWheel")
local RawClay = require("mer.ashfall.clay.RawClay")
local ClayWorking = require("mer.ashfall.clay.ClayWorking")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")
local Temper = require("mer.ashfall.clay.Temper")
local HeatedItem = require("mer.ashfall.clay.HeatedItem")
local Decoration = require("mer.ashfall.clay.Decoration.Decoration")
local BrickMould = require("mer.ashfall.clay.BrickMould")
local Brick = require("mer.ashfall.clay.Brick")
local Kiln = require("mer.ashfall.clay.Kiln")
--Event registrations
event.register("cellChanged", ClayDeposit.addClayToLoadedTerrain)
event.register("loaded", FiringController.onLoaded)

--Activate toolipts
event.register("activate", HeatedItem.onActivate)
event.register("activate", PotteryBreaking.onActivateBroken)
event.register("activate", DepositActivator.onActivate)
event.register("activate", UnfiredPottery.onActivate)
event.register("activate", BrickMould.onActivate)


--Tooltips - Higher priority = lower on tooltip
event.register("uiObjectTooltip", UnfiredPottery.onUiObjectTooltip, { priority = 10 })
event.register("uiObjectTooltip", FiredPottery.onUiObjectTooltip, { priority = 20 })
event.register("uiObjectTooltip", Temper.onUiObjectTooltip, { priority = 30 })
event.register("uiObjectTooltip", HeatedItem.onUiObjectTooltip, { priority = 40 })
event.register("uiObjectTooltip", DepositActivator.uiObjectTooltip)

Temper.registerTemperCompatibleItem(RawClay.rawClayId)


PotteryBreaking.initialise()
Temper.initialise()
Brick.initialise()
Kiln.initialise()
ClayWorking.initialise()

for _, recipeData in ipairs(clayConfig.potteryRecipes) do
    PotteryRecipe.registerRecipe(recipeData)
    if not recipeData.isBasic then
        Temper.registerTemperCompatibleItem(recipeData.id)
    end
end

for _, decalData in ipairs(clayConfig.potteryDecals) do
    PotteryDecals.register(decalData)
end

for _, potteryWheel in ipairs(clayConfig.spinningWheels) do
    PotteryWheel.registerSpinningWheel(potteryWheel)
end

for _, kilnData in ipairs(clayConfig.kilnDatas) do
    Campfire.registerCampfire(kilnData)
    Kiln.register(kilnData.id)
end

for _, activatorId in ipairs(clayConfig.clayWorkingActivatorIds) do
    ClayWorking.registerActivatorId(activatorId)
end

for _, decorationData in ipairs(clayConfig.decorations) do
    Decoration.registerDecoration(decorationData)
end

for _, rawBrickRecipe in ipairs(clayConfig.rawBrickRecipes) do
    Brick.rawMenuActivator:registerRecipe(rawBrickRecipe)
end

for _, firedBrickRecipe in ipairs(clayConfig.firedBrickRecipes) do
    Brick.firedMenuActivator:registerRecipe(firedBrickRecipe)
end