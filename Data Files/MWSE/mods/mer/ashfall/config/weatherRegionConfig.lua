local this = {}

local climate = {
    polar     = { min = -80, max = -50 },
    cold      = { min = -65, max = -40 },
    mild      = { min = -40, max = -20 },
    temperate = { min = -30, max = -10 },
    tropical  = { min = -20, max =   5 },
    dry       = { min = -35, max =  10 },
    volcanic  = { min =   0, max =  15 },
}
local defaultClimate = climate.temperate

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
    return this.regions[regionId:lower()] or defaultClimate
end
--Alter min/max weather values
this.regions = {
    --Solstheim
    ['moesring mountains region'] = climate.polar,
    ['felsaad coast region'] = climate.polar,
    ['isinfier plains region'] = climate.polar,
    ['brodir grove region'] = climate.cold,
    ['thirsk region'] = climate.cold,
    ['hirstaang forest region'] = climate.cold,
    --vvardenfell
    ['sheogorad'] = climate.cold,
    ['ashlands region'] = climate.cold,
    ["azura's coast region"] = climate.mild,
    ['ascadian isles region'] = climate.temperate, --perfectly normal weather here
    ['grazelands region'] = climate.temperate,
    ['bitter coast region'] = climate.tropical,
    ['west gash region'] = climate.dry,
    ['molag mar region'] = climate.volcanic,
    ['red mountain region'] = climate.volcanic,
    --tamriel rebuilt
    ["aranyon pass"] = climate.cold,
    ["boethiah's spire"] = climate.cold,
    ["telvanni isles"] = climate.cold,
    ["molagreahd"] = climate.mild,
    ["aanthirin"] = climate.temperate,
    ["alt orethan"] = climate.mild,
    ["helnim fields"] = climate.mild,
    ["lan orethan"] = climate.temperate,
    ["mephalan vales"] = climate.mild,
    ["nedothril"] = climate.mild,
    ["sacred lands"] = climate.mild,
    ["sundered scar"] = climate.temperate,
    ["othreleth woods"] = climate.tropical,
    ["shipal shin"] = climate.dry,
    ["thirr valley"] = climate.temperate,
    ["armun ashlands"] = climate.volcanic,
    ["ascadian bluffs"] = climate.temperate,
    ["calmbering moor"] = climate.mild,
    ["grey meadows"] = climate.mild,
    ["julan-shar"] = climate.cold,
    ["roth roryn"] = climate.mild,
    ["uld vraech"] = climate.polar,
    ["velothi mountains"] = climate.cold,
    ["arnesian jungle"] = climate.tropical,
    ["deshaan plains"] = climate.dry,
    ["mudflats"] = climate.temperate,
    ["salt marsh"] = climate.temperate,
    ["padomaic ocean"] = climate.mild,
    ["sea of ghosts"] = climate.cold,

    --tamriel rebuilt unimplemented:
    ["boethiah's spine"] = climate.temperate,
    ["balachen corridor"] = climate.temperate,
    ["dolmolag peninsula"] = climate.temperate,
    ["molkadh mountains"] = climate.temperate,
    ["nebet peninsula"] = climate.temperate,
    ["amurbal peninsula"] = climate.temperate,
    ["neidweisra peninsula"] = climate.temperate,
    ["ouadavohr"] = climate.temperate,
    ["shipal-shin"] = climate.temperate,
    ["clambering moor"] = climate.temperate,
}

return this


