local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local teaConfig = common.staticConfigs.teaConfig
------------------
--Tooltips
-----------------
local function updateTooltip(e)
    common.log:trace("Campfire tooltip")
    local function centerText(element)
        element.autoHeight = true
        element.autoWidth = true
        element.wrapText = true
        element.justifyText = "center" 
    end
    local label = e.label
    local labelBorder = e.element
    local campfire = e.reference
    local parentNode = e.parentNode

    --Do some fancy campfire stuff
    local attachments = {
        "Grill",
        "Kettle",
        "Cooking Pot",
        "Supports",
    }
    local attachment = parentNode.name
    if table.find(attachments, attachment) then
        label.text = attachment
    end

    --Add special fields
    if label.text == "Campfire" and campfire.data.dynamicConfig and campfire.data.dynamicConfig.campfire == "dynamic" then
        local fuelLevel = campfire.data.fuelLevel or 0
        if fuelLevel > 0 then
            local fuelLabel = labelBorder:createLabel{
                text = string.format("Fuel: %.1f hours", fuelLevel )
            }
            centerText(fuelLabel)
        end
    elseif label.text == "Kettle" or label.text == "Cooking Pot" then
        local waterAmount = campfire.data.waterAmount
        if waterAmount then
            --WATER
            local waterHeat = campfire.data.waterHeat or 0
            local waterLabel = labelBorder:createLabel{
                text = string.format(
                    "Water: %d/%d %s| Heat: %d/100", 
                    math.ceil(waterAmount), 
                    common.staticConfigs.capacities[campfire.data.utensil], 
                    ( campfire.data.waterType == "dirty" and "(Dirty) " or ""),
                    waterHeat)
            }
            centerText(waterLabel)

            if teaConfig.teaTypes[campfire.data.waterType] then
                local progress = campfire.data.teaProgress or 0
                local teaData = teaConfig.teaTypes[campfire.data.waterType]
                labelBorder:createDivider()
                local teaLabelText = teaData.teaName
                if campfire.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
                    teaLabelText = teaLabelText .. " (Cold)"
                elseif progress < 100 then
                    teaLabelText = string.format("%s (%d%% Brewed)", teaLabelText, progress)
                end

                local teaLabel = labelBorder:createLabel({ text = teaLabelText })
                teaLabel.color = tes3ui.getPalette("header_color")
                centerText(teaLabel)
                if progress >= 100 then
                    local effectBlock = labelBorder:createBlock{}
                    effectBlock.childAlignX = 0.5
                    effectBlock.autoHeight = true
                    effectBlock.autoWidth = true
                    effectBlock.flowDirection = "left_to_right"

                    local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
                    icon.height = 16
                    icon.width = 16
                    icon.scaleMode = true
                    icon.borderAllSides = 1
                    
                    local effectLabelText = teaData.effectDescription
                    local effectLabel = effectBlock:createLabel{ text = effectLabelText }
                    effectLabel.borderLeft = 4
                end
            end

            if campfire.data.stewLevels then

                labelBorder:createDivider()

                local progress = ( campfire.data.stewProgress or 0 )
                local progressText

                if campfire.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
                    progressText = "Stew (Cold)"
                elseif progress < 100 then
                    progressText = string.format("Stew (%d%% Cooked)", progress ) 
                else 
                    progressText = "Stew (Cooked)"
                end
                local stewProgressLabel = labelBorder:createLabel({ text = progressText })
                stewProgressLabel.color = tes3ui.getPalette("header_color")
                centerText(stewProgressLabel)

                
                for foodType, ingredLevel in pairs(campfire.data.stewLevels) do
                    local value = math.min(ingredLevel, 100)
                    local stewBuff = foodConfig.getStewBuffForFoodType(foodType)
                    local spell = tes3.getObject(stewBuff.id)
                    local effect = spell.effects[1]

                    local ingredText = string.format("(%d%% %s)", value, foodType )
                    local ingredLabel

                    if progress >= 100 then
                        local block = labelBorder:createBlock{}
                        block.autoHeight = true
                        block.autoWidth = true
                        block.childAlignX = 0.5

                        
                        local image = block:createImage{path=("icons\\" .. effect.object.icon)}
                        image.wrapText = false
                        image.borderLeft = 4

                        --"Fortify Health"
                        local statName
                        if effect.attribute ~= -1 then
                            local stat = effect.attribute
                            statName = tes3.findGMST(888 + stat).value
                        elseif effect.skill ~= -1 then
                            local stat = effect.skill
                            statName = tes3.findGMST(896 + stat).value
                        end
                        local effectNameText
                        local effectName = tes3.findGMST(1283 + effect.id).value
                        if statName then
                            effectNameText = effectName:match("%S+") .. " " .. statName
                        else
                            effectNameText = effectName
                        end
                        --points " 25 points "
                        local pointsText = string.format("%d pts", common.helper.calculateStewBuffStrength(value, stewBuff.min, stewBuff.max) )
                        --for X hours
                        local duration = common.helper.calculateStewBuffDuration()
                        local hoursText = string.format("for %d hour%s", duration, (duration >= 2 and "s" or "") )

                        ingredLabel = block:createLabel{text = string.format("%s %s: %s %s %s", spell.name, ingredText, effectNameText, pointsText, hoursText) }
                        ingredLabel.wrapText = false
                        ingredLabel.borderLeft = 4
                    else
                        ingredLabel = labelBorder:createLabel{text = ingredText }
                        centerText(ingredLabel)
                    end
                end
            end
        end
    end
end

event.register("Ashfall:Activator_tooltip", updateTooltip, { filter = "campfire" })