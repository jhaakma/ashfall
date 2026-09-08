--[[
    This script provides a function to dynamically re-calculate normals on a NiTriShapeData structure.
    Uses ffi to run quick enough to call each frame, useful for calling during a shapekey animation.
]]

local ffi = require("ffi")

ffi.cdef([[
    typedef struct {
        float x;
        float y;
    } NiPoint2;

    typedef struct {
        float x;
        float y;
        float z;
    } NiPoint3;

    typedef struct {
        unsigned char b;
        unsigned char g;
        unsigned char r;
        unsigned char a;
    } NiColorA;

    typedef struct {
        unsigned short v0;
        unsigned short v1;
        unsigned short v2;
    } Triangle;

    typedef struct {
        void* vtable;
        int refCount;
        unsigned short vertexCount;
        unsigned short textureSets;
        NiPoint3 center;
        float radius;
        NiPoint3* vertex;
        NiPoint3* normal;
        NiColorA* color;
        NiPoint2* textureCoords;
        unsigned int uniqueID;
        unsigned short revisionID;
        char padding[2];
        unsigned short triangleCount;
        unsigned int triangleListLength;
        Triangle* triangleList;
        void* sharedNormals;
        unsigned short sharedNormalsArraySize;
    } NiTriShapeData;

]])

local NormalsHack = {}

---@param trishapeData niTriShapeData
function NormalsHack.fixNormals(trishapeData)
    local ptr = mwse.memory.addressOf(trishapeData)
    local data = ffi.cast("NiTriShapeData*", ptr)[0]

    -- First, calculate flat normals from triangle geometry

    -- Reset all normals to zero
    ffi.fill(data.normal, data.vertexCount, 0)

    local temp1 = ffi.new("NiPoint3")
    local temp2 = ffi.new("NiPoint3")
    local temp3 = ffi.new("NiPoint3")

    -- Calculate face normals and accumulate them to vertex normals
    for i = 0, data.triangleCount - 1 do
        local triangle = data.triangleList[i]

        local i0 = triangle.v0
        local i1 = triangle.v1
        local i2 = triangle.v2

        -- Get the actual vertex positions
        local v0 = data.vertex[i0]
        local v1 = data.vertex[i1]
        local v2 = data.vertex[i2]

        -- Calculate edges
        temp1.x = v1.x - v0.x
        temp1.y = v1.y - v0.y
        temp1.z = v1.z - v0.z
        temp2.x = v2.x - v1.x
        temp2.y = v2.y - v1.y
        temp2.z = v2.z - v1.z

        -- Calculate face normal using cross product
        temp3.x = temp1.y * temp2.z - temp1.z * temp2.y
        temp3.y = temp1.z * temp2.x - temp2.z * temp1.x
        temp3.z = temp1.x * temp2.y - temp1.y * temp2.x

        -- Accumulate this face normal to each vertex of the triangle
        for _, j in ipairs({ i0, i1, i2}) do
            data.normal[j].x = data.normal[j].x + temp3.x
            data.normal[j].y = data.normal[j].y + temp3.y
            data.normal[j].z = data.normal[j].z + temp3.z
        end
    end

    -- Normalize all accumulated normals
    for i = 0, data.vertexCount - 1 do
        local len = math.sqrt(
            data.normal[i].x * data.normal[i].x +
            data.normal[i].y * data.normal[i].y +
            data.normal[i].z * data.normal[i].z
        )
        if len > 1e-6 then
            data.normal[i].x = data.normal[i].x / len
            data.normal[i].y = data.normal[i].y / len
            data.normal[i].z = data.normal[i].z / len
        end
    end

    -- Now smooth normals by averaging normals of vertices at the same position
    local sharedNormals = {}

    for i = 0, data.vertexCount - 1 do
        local k = ("%.3f,%.3f,%.3f"):format(data.vertex[i].x, data.vertex[i].y, data.vertex[i].z)
        if sharedNormals[k] then
            table.insert(sharedNormals[k], i)
        else
            sharedNormals[k] = {i}
        end
    end

    for _, indices in pairs(sharedNormals) do
        -- computes smooth normal for this group
        temp1.x = 0
        temp1.y = 0
        temp1.z = 0
        for _, i in ipairs(indices) do
            temp1.x = data.normal[i].x
            temp1.y = data.normal[i].y
            temp1.z = data.normal[i].z
        end
        -- normalize
        local len = math.sqrt(temp1.x * temp1.x + temp1.y * temp1.y + temp1.z * temp1.z)
        if len > 1e-6 then
            temp1.x = temp1.x / len
            temp1.y = temp1.y / len
            temp1.z = temp1.z / len
        end
        -- assign normal to each vertex in group
        for _, i in ipairs(indices) do
            data.normal[i] = temp1
        end
    end
end

return NormalsHack
