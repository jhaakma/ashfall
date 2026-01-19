local this = {}

this.climate = {
    polar     = { min = -80, max = -50 },
    cold      = { min = -65, max = -40 },
    mild      = { min = -40, max = -20 },
    temperate = { min = -30, max = -10 },
    tropical  = { min = -20, max =   5 },
    dry       = { min = -35, max =  10 },
    volcanic  = { min =   0, max =  15 },
}
local defaultClimate = this.climate.temperate

this.weathers = {
    [tes3.weather.blight] = 40,
    [tes3.weather.ash] = 30,
    [tes3.weather.clear] = 0,
    [tes3.weather.cloudy] = -10,
    [tes3.weather.overcast] = -20,
    [tes3.weather.foggy] = -25,
    [tes3.weather.rain] = -35,
    [tes3.weather.thunder] = -45,
    [tes3.weather.snow] = -55,
    [tes3.weather.blizzard] = -65,
}
local defaultWeatherTemp = 0

---@class Ashfall.CustomWeather.RegionConditions
---@field minGridX integer?
---@field maxGridX integer?
---@field minGridY integer?
---@field maxGridY integer?


this.customWeathers = {
    sporefall = {
        temp = 0,
        originalWeatherIndex = tes3.weather.snow,
        regions = {
            ["othreleth woods region"] = {},
            ["thirr valley region"] = {},
            ["aanthirin region"] = {},
            ["shipal-shin region"] = {},
            ["armun ashlands region"] = {
                minGridX = -11
            }
        }
    },
    sandstorm = {
        temp = 25,
        originalWeatherIndex = tes3.weather.ash,
        regions = {
            ["shipal-shin region"] = {},
            [ "othreleth woods region" ] = {
                maxGridY = -39
            },
            ["thirr valley region" ] = {
                maxGridY = -39
            },
        }
    },
    tropicalStorm = {
        temp = -40,
        originalWeatherIndex = tes3.weather.ash,
        regions = {
            ["abecean sea region" ] = {},
            ["stirk isle region" ] = {},
            ["gold coast region" ] = {},
            ["gilded hills region" ] = {},
            ["dasek marsh region" ] = {},
            ["kvetchi pass region" ] = {},
            ["colovian highlands region"] = {},
        }
    },
}

---Check if player cell is within grid conditions
---@param gridConditions Ashfall.CustomWeather.RegionConditions
---@return boolean
local function playerWithinGridConditions(gridConditions)
    local cell = tes3.player.cell
    if cell.isInterior then return true end
    local gridX = cell.gridX
    local gridY = cell.gridY
    if gridConditions.minGridX and gridX < gridConditions.minGridX then
        return false
    end
    if gridConditions.maxGridX and gridX > gridConditions.maxGridX then
        return false
    end
    if gridConditions.minGridY and gridY < gridConditions.minGridY then
        return false
    end
    if gridConditions.maxGridY and gridY > gridConditions.maxGridY then
        return false
    end
    return true
end

function this.getWeatherTemperature(weatherId)
    local cell = tes3.player.cell
    if not cell.isInterior then
        local region = tes3.player and tes3.player.cell.region
        local regionId = region and region.id:lower()
        mwse.log("region: %s", regionId)
        for customWeatherId, customWeatherData in pairs(this.customWeathers) do
            local weatherMatch = customWeatherData.originalWeatherIndex == weatherId
            local regionData = customWeatherData.regions[regionId]
            if weatherMatch and regionData then
                if playerWithinGridConditions(regionData) then
                    mwse.log("Custom weather match: %s", customWeatherId)
                    return customWeatherData.temp
                end
            end
        end
    end
    return this.weathers[weatherId] or defaultWeatherTemp
end

function this.getRegionData(regionId)
    return this.regions[regionId:lower()] or defaultClimate
end

--Alter min/max weather values
this.regions = {
    --Solstheim
    ['moesring mountains region'] = this.climate.polar,
    ['felsaad coast region'] = this.climate.polar,
    ['isinfier plains region'] = this.climate.polar,
    ['brodir grove region'] = this.climate.cold,
    ['thirsk region'] = this.climate.cold,
    ['hirstaang forest region'] = this.climate.cold,
    --vvardenfell
    ['sheogorad'] = this.climate.cold,
    ['ashlands region'] = this.climate.cold,
    ["azura's coast region"] = this.climate.mild,
    ['ascadian isles region'] = this.climate.temperate, --perfectly normal weather here
    ['grazelands region'] = this.climate.temperate,
    ['bitter coast region'] = this.climate.tropical,
    ['west gash region'] = this.climate.dry,
    ['molag mar region'] = this.climate.volcanic,
    ['red mountain region'] = this.climate.volcanic,
    --tamriel rebuilt
    ["aranyon pass"] = this.climate.cold,
    ["boethiah's spire"] = this.climate.cold,
    ["telvanni isles"] = this.climate.cold,
    ["molagreahd"] = this.climate.mild,
    ["aanthirin"] = this.climate.temperate,
    ["alt orethan"] = this.climate.mild,
    ["helnim fields"] = this.climate.mild,
    ["lan orethan"] = this.climate.temperate,
    ["mephalan vales"] = this.climate.mild,
    ["nedothril"] = this.climate.mild,
    ["sacred lands"] = this.climate.mild,
    ["sundered scar"] = this.climate.temperate,
    ["othreleth woods"] = this.climate.tropical,
    ["shipal shin"] = this.climate.dry,
    ["thirr valley"] = this.climate.temperate,
    ["armun ashlands"] = this.climate.volcanic,
    ["ascadian bluffs"] = this.climate.temperate,
    ["calmbering moor"] = this.climate.mild,
    ["grey meadows"] = this.climate.mild,
    ["julan-shar"] = this.climate.cold,
    ["roth roryn"] = this.climate.mild,
    ["uld vraech"] = this.climate.polar,
    ["velothi mountains"] = this.climate.cold,
    ["arnesian jungle"] = this.climate.tropical,
    ["deshaan plains"] = this.climate.dry,
    ["mudflats"] = this.climate.temperate,
    ["salt marsh"] = this.climate.temperate,
    ["padomaic ocean"] = this.climate.mild,
    ["sea of ghosts"] = this.climate.cold,

    --tamriel rebuilt unimplemented:
    ["boethiah's spine"] = this.climate.temperate,
    ["balachen corridor"] = this.climate.temperate,
    ["dolmolag peninsula"] = this.climate.temperate,
    ["molkadh mountains"] = this.climate.temperate,
    ["nebet peninsula"] = this.climate.temperate,
    ["amurbal peninsula"] = this.climate.temperate,
    ["neidweisra peninsula"] = this.climate.temperate,
    ["ouadavohr"] = this.climate.temperate,
    ["shipal-shin"] = this.climate.temperate,
    ["clambering moor"] = this.climate.temperate,

    --Stupid TR changing ids on me. Get your shit together Tamriel Rebuilt, make an interop file already
    ["aranyon pass region"] = this.climate.cold,
    ["boethiah's spire region"] = this.climate.cold,
    ["telvanni isles region"] = this.climate.cold,
    ["molagreahd region"] = this.climate.mild,
    ["aanthirin region"] = this.climate.temperate,
    ["alt orethan region"] = this.climate.mild,
    ["helnim fields region"] = this.climate.mild,
    ["lan orethan region"] = this.climate.temperate,
    ["mephalan vales region"] = this.climate.mild,
    ["nedothril region"] = this.climate.mild,
    ["sacred lands region"] = this.climate.mild,
    ["sundered scar region"] = this.climate.temperate,
    ["othreleth woods region"] = this.climate.tropical,
    ["shipal shin region"] = this.climate.dry,
    ["thirr valley region"] = this.climate.temperate,
    ["armun ashlands region"] = this.climate.volcanic,
    ["ascadian bluffs region"] = this.climate.temperate,
    ["calmbering moor region"] = this.climate.mild,
    ["grey meadows region"] = this.climate.mild,
    ["julan-shar region"] = this.climate.cold,
    ["roth roryn region"] = this.climate.mild,
    ["uld vraech region"] = this.climate.polar,
    ["velothi mountains region"] = this.climate.cold,
    ["arnesian jungle region"] = this.climate.tropical,
    ["deshaan plains region"] = this.climate.dry,
    ["mudflats region"] = this.climate.temperate,
    ["salt marsh region"] = this.climate.temperate,
    ["padomaic ocean region"] = this.climate.mild,
    ["sea of ghosts region"] = this.climate.cold,
    ["boethiah's spine region"] = this.climate.temperate,
    ["balachen corridor region"] = this.climate.temperate,
    ["dolmolag peninsula region"] = this.climate.temperate,
    ["molkadh mountains region"] = this.climate.temperate,
    ["nebet peninsula region"] = this.climate.temperate,
    ["amurbal peninsula region"] = this.climate.temperate,
    ["neidweisra peninsula region"] = this.climate.temperate,
    ["ouadavohr region"] = this.climate.temperate,
    ["shipal-shin region"] = this.climate.temperate,
    ["clambering moor region"] = this.climate.temperate,


    --Shotn
    ["lorchwuir hearth region"] = this.climate.cold,
    ["vorndgad forest region"] = this.climate.cold,
    ["druadach highlands region"] = this.climate.polar,
    ["sundered hills region"] = this.climate.cold,
    ["midkarth region"] = this.climate.cold,
    ["falkheim region"] = this.climate.polar,
}

return this


