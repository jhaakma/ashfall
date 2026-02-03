local ClayDeposit = require("mer.ashfall.clay.ClayDeposit")
local DepositActivator = require("mer.ashfall.clay.DepositActivator")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryDecals = require("mer.ashfall.clay.PotteryDecals")
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
--Event registrations
event.register("cellChanged", ClayDeposit.addClayToLoadedTerrain)
event.register("activate", DepositActivator.onActivate)
event.register("loaded", FiringController.onLoaded)
event.register("uiObjectTooltip", UnfiredPottery.onUiObjectTooltip)
event.register("activate", UnfiredPottery.onActivate)
event.register("uiObjectTooltip", FiredPottery.onUiObjectTooltip)
event.register("activate", FiredPottery.onActivate)


Temper.registerTemperCompatibleItem(RawClay.rawClayId)

for _, recipeData in ipairs(clayConfig.potteryRecipes) do
    PotteryRecipe.registerRecipe(recipeData)
    Temper.registerTemperCompatibleItem(recipeData.id)
end

for _, decalData in ipairs(clayConfig.potteryDecals) do
    PotteryDecals.register(decalData)
end

for _, potteryWheel in ipairs(clayConfig.spinningWheels) do
    PotteryWheel.registerSpinningWheel(potteryWheel)
end

for _, kilnData in ipairs(clayConfig.kilnDatas) do
    Campfire.registerCampfire(kilnData)
end

for _, activatorId in ipairs(clayConfig.clayWorkingActivatorIds) do
    ClayWorking.registerActivatorId(activatorId)
end

PotteryBreaking.initialise()
ClayWorking.initialise() --must run after recipes registered
Temper.initialise()
