local Debris = {}

Debris.minPlaceDistance = 100
Debris.maxPlaceDistance = 500
Debris.minNumPerRef = 0
Debris.maxNumPerRef = 2
Debris.hoursToRefresh = 24 * 3
Debris.minScale = 80
Debris.maxScale = 100

function Debris.new(data)
    setmetatable(data, Debris)
    return data
end



return Debris