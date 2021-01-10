--[[
    Script to check if player is holding a torch and set torchTemp
]]--
local common = require("mer.ashfall.common.common")
local this = {}

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("torchTemp")

local minHeat = 5
local maxHeat = 15

function this.calculateTorchTemp()
    local torchStack = tes3.mobilePlayer.torchSlot
    if torchStack and torchStack.object.name and string.find(torchStack.object.name:lower(), "torch") then
        local maxTime = torchStack.object.time
        local currentTime = torchStack.object:getTimeLeft(torchStack)
        common.data.torchTemp =  math.ceil( math.remap( currentTime, 0, maxTime, minHeat, maxHeat ) )
    else
        common.data.torchTemp = 0
    end
end
return this