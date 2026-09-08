local SnapRegistry = require("CraftingFramework.components.Positioner.SnapRegistry")

local snapConfigs = {
    {
        meshPath = "ashfall\\clay\\brickwall_01.nif",
        snapNodes = {
            BRICK_LEFT = "brick_left",
            BRICK_RIGHT = "brick_right",
            SNAP_TOP = "snap_top",
            SNAP_BOTTOM = "snap_bottom",
        }
    },
    {
        meshPath = "ashfall\\craft\\wall_wood.nif",
        snapNodes = {
            FLOOR_CORNER = "floor_corner",
            FLOOR_SIDE = "floor_side",
            ROOF_CORNER = "roof_corner",
            ROOF_SIDE = "roof_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\doorway_01.nif",
        snapNodes = {
            FLOOR_CORNER = "floor_corner",
            FLOOR_SIDE = "floor_side",
            ROOF_CORNER = "roof_corner",
            ROOF_SIDE = "roof_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\window_01.nif",
        snapNodes = {
            FLOOR_CORNER = "floor_corner",
            FLOOR_SIDE = "floor_side",
            ROOF_CORNER = "roof_corner",
            ROOF_SIDE = "roof_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\roof_01.nif",
        snapNodes = {
            ROOF_SIDE = "roof_side",
            ROOF_CORNER = "roof_corner",
        }
    },
    {
        meshPath = "ashfall\\craft\\roof_02.nif",
        snapNodes = {
            ROOF_SIDE = "roof_side",
            ROOF_CORNER = "roof_corner",
        }
    },
    {
        meshPath = "ashfall\\craft\\platform_01.nif",
        snapNodes = {
            FLOOR_CORNER = "floor_corner",
            FLOOR_SIDE = "floor_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\floor_01.nif",
        snapNodes = {
            FLOOR_CORNER = "floor_corner",
            FLOOR_SIDE = "floor_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\fence_01.nif",
        snapNodes = {
            WALL_TOP = "wall_top",
            WALL_BOTTOM = "wall_bottom",
            WALL_SIDE = "floor_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\steps_lrg_01.nif",
        snapNodes = {
            STAIR_TOP = "stair_top",
            STAIR_BOTTOM = "stair_bottom",
            ROOF_SIDE = "roof_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\steps_sm_01.nif",
        snapNodes = {
            STAIR_TOP = "stair_top",
            STAIR_BOTTOM = "floor_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\awning_sm_01.nif",
        snapNodes = {
            ROOF_SIDE = "roof_side",
        }
    },
    {
        meshPath = "ashfall\\craft\\awning_lg_01.nif",
        snapNodes = {
            ROOF_SIDE = "roof_side",
        }
    }
}

for _, config in ipairs(snapConfigs) do
    SnapRegistry.registerMesh(config)
end



local rules = {
    {
        name = "brick_left",
        compatibleWith = {
            brick_left = true,
            brick_right = true,
        },
    },
    {
        name = "brick_right",
        compatibleWith = {
            brick_left = true,
            brick_right = true,
        },
    },
    {
        name = "snap_left",
        compatibleWith = {
            snap_left = true,
            snap_right = true,
        },
    },
    {
        name = "snap_right",
        compatibleWith = {
            snap_left = true,
            snap_right = true,
        },
    },
    {
        name = "snap_top",
        compatibleWith = {
            snap_bottom = true,
        },
    },
    {
        name = "snap_bottom",
        compatibleWith = {
            snap_top = true,
        },
    },
    {
        name = "roof_side",
        compatibleWith = {
            roof_side = true,
        },
    },
    {
        name = "roof_corner",
        compatibleWith = {
            roof_corner = true,
        },
    },
    {
        name = "floor_side",
        compatibleWith = {
            floor_side = true,
            roof_side = true
        },
    },
    {
        name = "floor_corner",
        compatibleWith = {
            floor_corner = true,
        },
    },
    {
        name = "stair_top",
        compatibleWith = {
            stair_bottom = true,
        },
    },
    {
        name = "stair_bottom",
        compatibleWith = {
            stair_top = true,
            floor_side = true,
        },
    }
}

for _, rule in ipairs(rules) do
    SnapRegistry.registerSnapRule(rule)
end
