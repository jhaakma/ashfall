local this = {}

local CLIMATE = {
    polar     = { min = -80, max = -50 },
    cold      = { min = -65, max = -40 },
    mild      = { min = -40, max = -20 },
    temperate = { min = -30, max = -10 },
    tropical  = { min = -20, max =   5 },
    dry       = { min = -35, max =  10 },
    volcanic  = { min =   0, max =  15 },
}
local defaultClimate = CLIMATE.temperate

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

function this.getWeatherTemperature(weatherId)
    return this.weathers[weatherId] or defaultWeatherTemp
end

function this.getRegionData(regionId)
    return this.regions[regionId] or defaultClimate
end
--Alter min/max weather values
this.regions = {
    --Solstheim
    ['Moesring Mountains Region'] = CLIMATE.polar,
    ['Felsaad Coast Region'] = CLIMATE.polar,
    ['Isinfier Plains Region'] = CLIMATE.polar,
    ['Brodir Grove Region'] = CLIMATE.cold,
    ['Thirsk Region'] = CLIMATE.cold,
    ['Hirstaang Forest Region'] = CLIMATE.cold,
    --Vvardenfell
    ['Sheogorad'] = CLIMATE.cold,
    ['Ashlands Region'] = CLIMATE.cold,
    ["Azura's Coast Region"] = CLIMATE.mild,
    ['Ascadian Isles Region'] = CLIMATE.temperate, --Perfectly normal weather here
    ['Grazelands Region'] = CLIMATE.temperate,
    ['Bitter Coast Region'] = CLIMATE.tropical,
    ['West Gash Region'] = CLIMATE.dry,
    ['Molag Mar Region'] = CLIMATE.volcanic,
    ['Red Mountain Region'] = CLIMATE.volcanic,
    --Tamriel Rebuilt
    ["Aranyon Pass"] = CLIMATE.cold,
    ["Boethiah's Spire"] = CLIMATE.cold,
    ["Telvanni Isles"] = CLIMATE.cold,
    ["Molagreahd"] = CLIMATE.mild,
    ["Aanthirin"] = CLIMATE.temperate,
    ["Alt Orethan"] = CLIMATE.mild,
    ["Helnim Fields"] = CLIMATE.mild,
    ["Lan Orethan"] = CLIMATE.temperate,
    ["Mephalan Vales"] = CLIMATE.mild,
    ["Nedothril"] = CLIMATE.mild,
    ["Sacred Lands"] = CLIMATE.mild,
    ["Sundered Scar"] = CLIMATE.temperate,
    ["Othreleth Woods"] = CLIMATE.tropical,
    ["Shipal Shin"] = CLIMATE.dry,
    ["Thirr Valley"] = CLIMATE.temperate,
    ["Armun Ashlands"] = CLIMATE.volcanic,
    ["Ascadian Bluffs"] = CLIMATE.temperate,
    ["Calmbering Moor"] = CLIMATE.mild,
    ["Grey Meadows"] = CLIMATE.mild,
    ["Julan-Shar"] = CLIMATE.cold,
    ["Roth Roryn"] = CLIMATE.mild,
    ["Uld Vraech"] = CLIMATE.polar,
    ["Velothi Mountains"] = CLIMATE.cold,
    ["Arnesian Jungle"] = CLIMATE.tropical,
    ["Deshaan Plains"] = CLIMATE.dry,
    ["Mudflats"] = CLIMATE.temperate,
    ["Salt Marsh"] = CLIMATE.temperate,
    ["Padomaic Ocean"] = CLIMATE.mild,
    ["Sea of Ghosts"] = CLIMATE.cold,

    --Tamriel Rebuilt unimplemented:
    ["Boethiah's Spine"] = CLIMATE.temperate,
    ["Balachen Corridor"] = CLIMATE.temperate,
    ["Dolmolag Peninsula"] = CLIMATE.temperate,
    ["Molkadh Mountains"] = CLIMATE.temperate,
    ["Nebet Peninsula"] = CLIMATE.temperate,
    ["Amurbal Peninsula"] = CLIMATE.temperate,
    ["Neidweisra Peninsula"] = CLIMATE.temperate,
    ["Ouadavohr"] = CLIMATE.temperate,
    ["Shipal-Shin"] = CLIMATE.temperate,
    ["Clambering Moor"] = CLIMATE.temperate,
}

return this


