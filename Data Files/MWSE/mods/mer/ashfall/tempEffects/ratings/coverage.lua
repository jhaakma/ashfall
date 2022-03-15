local config = require("mer.ashfall.config").config

local bodyPartCoverages = {}
do
    --[[
        "Coverage" represents how much of your body a piece of clothing protects.
        This is based on which bodyparts are used by that item.

        Different bodyparts represent a different % of your body
    ]]
    local rawPartCoverages = {
        head = 2,
        hair = 4,
        neck = 1,
        chest = 6,
        groin = 3,
        skirt = 3,
        rightHand = 1,
        leftHand = 1,
        rightWrist = 1,
        leftWrist = 1,
        rightForearm = 1,
        leftForearm = 1,
        rightUpperArm = 1,
        leftUpperArm = 1,
        rightFoot = 1,
        leftFoot = 1,
        rightAnkle = 1,
        leftAnkle = 1,
        rightKnee = 1,
        leftKnee = 1,
        rightUpperLeg = 1,
        leftUpperLeg = 1,
        rightPauldron = 1,
        leftPauldron = 1,
    }
    --Normalise values by dividing by total
    local totalCoverageValue = 0
    for _, v in pairs(rawPartCoverages) do
        totalCoverageValue = totalCoverageValue + v
    end
    for partName, v in pairs(rawPartCoverages) do
        bodyPartCoverages[tes3.activeBodyPart[partName]] = v / totalCoverageValue
    end
end

local generalRatings = {
    steel = 100,
    leather = 100,
    fur = 50,
    chain = 30,

    common = 40,
    expensive = 50,
    extravagant = 60,
    exquisite = 70,
}


local function getProtectionForItem(item)


end

--[[
    Returns a list of bodyParts and the protection
]]
local function getPartRatingsForItem(item)
    local partRatings = {}
    for _, part in pairs(item.parts) do
        local partCoverage = bodyPartCoverages[part.type]
        if partCoverage then
            partRatings[part.type] = partCoverage
        end
    end
    return partRatings
end