local common = require ("mer.ashfall.common.common")
local this = {}
local metalPatterns = {
    "iron", "steel", "metal", "pewter", "copper"
}

local function findLowestAndHighest(sceneNode) 
    local lowest_vertex = tes3vector3.new(0, 0, math.huge)
    local highest_vertex = tes3vector3.new(0, 0, -math.huge)
    for node in table.traverse{sceneNode} do
        if node.RTTI.name == "NiTriShape" then
            local isMetal = false
            for _, pattern in ipairs(metalPatterns) do
                local texture = node:getProperty(0x4)
                if texture then
                    if string.find(texture.maps[1].texture.fileName:lower(), pattern) then
                        isMetal = true
                    end
                end
            end
            if isMetal then
                for i, vertex in ipairs(node.vertices) do
                    if vertex.z < lowest_vertex.z then
                        lowest_vertex = vertex
                    end
                    if vertex.z > highest_vertex.z then
                        highest_vertex = vertex
                    end
                end
            end
        end
    end
    return lowest_vertex.z, highest_vertex.z
end

local function colorFromLowToHigh(node, amount, low, high)
    common.log:trace("amount: %s, low: %s, high: %s, ", amount, low, high)


    local maxBrightness = math.remap(amount, 0, 100, 255, 245)

    high = high * math.remap(amount, 0, 100, 1, 1.4)

    local redLow = math.remap(amount, 0, 100, maxBrightness, 70)
    local redHigh = math.min(maxBrightness, redLow + maxBrightness)
   
    local greenLow = math.remap(amount, 0, 100, maxBrightness, 35)
    local greenHigh = math.min(maxBrightness, greenLow + maxBrightness)

    local blueLow = math.remap(amount, 0, 100, maxBrightness, 15)
    local blueHigh = math.min(maxBrightness, blueLow + maxBrightness)

    node.data = node.data:copy()
    local didApplyColor = false
    for i, c in pairs(node.data.colors) do
        didApplyColor = true
        local vertex = node.data.vertices[i]
        c.r = math.remap(vertex.z, low, high, redLow, redHigh)
        c.g = math.remap(vertex.z, low, high, greenLow, greenHigh)
        c.b = math.remap(vertex.z, low, high, blueLow, blueHigh)
        c.a = math.remap(vertex.z, low, high, 0, 255)
    end
    node.data:markAsChanged()
    node:update()
    return didApplyColor
end



function this.addPatina(rootNode, amount)
    common.log:trace("+++++ADD PATINA")
    if not rootNode then return end
    if not amount then return end
    local low, high = findLowestAndHighest(rootNode)
    local appliedPatina = false
    for node in table.traverse{rootNode} do
        if node.RTTI.name == "NiTriShape" then
            local texture = node:getProperty(0x4)
            if texture then
                for _, pattern in ipairs(metalPatterns) do
                    if string.find(texture.maps[1].texture.fileName:lower(), pattern) then
                        common.log:trace("adding patina amount to %s", amount)
                        common.log:trace(texture.maps[1].texture.fileName)
                        if colorFromLowToHigh(node, amount, low, high) then
                            appliedPatina = true
                        end
                    end
                end
            end
        end
    end
    return appliedPatina
end

local function doPatinaDrop(e)
    if e.reference and e.reference.sceneNode and e.reference.data then
        local data = e.reference.data
        local patinaAmount = data.patinaAmount
        if patinaAmount then
            common.log:trace("doPatinaDrop amount: %s", patinaAmount)
            if patinaAmount > 0 and e.reference.position.z < e.reference.cell.waterLevel then
                data.patinaAmount = nil

                tes3.messageBox("You wash your %s.", common.helper.getGenericUtensilName(e.reference.object))
                
                local cleanSeconds = 2
                --Play some splashy sounds
                tes3.playSound {sound = 'Swim Left'}
                timer.start {
                    type = timer.real,
                    duration = cleanSeconds / 3,
                    callback = function()
                        tes3.playSound {sound = 'Swim Left'}
                    end
                }
                timer.start {
                    type = timer.real,
                    duration = cleanSeconds / 2,
                    callback = function()
                        tes3.playSound {sound = 'Swim Right'}
                    end
                }
            end
            
            this.addPatina(e.reference.sceneNode, e.reference.data.patinaAmount)
        end
    end
end
event.register("itemDropped", doPatinaDrop)
event.register("referenceActivated", doPatinaDrop)




return this