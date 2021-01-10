local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)
 
local function matrixFromAxisAngle(angle, axis)
    local cos = math.cos(angle)
    local dir = axis:normalized()
 
    local mat = tes3matrix33.new(cos, 0, 0, 0, cos, 0, 0, 0, cos)
    mat = mat + dir:outerProduct(dir) * (1 - cos)
 
    dir = dir * math.sin(angle)
    mat = mat + tes3matrix33.new(0, -dir.z, dir.y, dir.z, 0, -dir.x, -dir.y, dir.x, 0)
 
    return mat
end
 
local function align_vectors(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()
 
    local axis = vec1:cross(vec2)
    local norm = math.clamp(axis:length(), -1, 1)
 
    local dir = vec1:dot(vec2)
    if dir < -1e-5 then
        dir = -1
    elseif dir > 1e-5 then
        dir = 1
    else
        dir = 0
    end
 
    if norm < 1e-5 then
        return ID33 * dir
    end
 
    angle = math.asin(norm)
    if dir < 0 then
        angle = math.pi - angle
    end
 
    return matrixFromAxisAngle(angle, axis)
end
 
-- example
--local up = tes3vector3.new(0, 0, 1)
--local rayhit = tes3.rayTest{position=eyepos, direction=eyevec}
--target.orientation = align_vectors(up, rayhit.normal)