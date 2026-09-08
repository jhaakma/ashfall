# Shaping Animation
- Use _MouldAnimStaging.blend
- Create new Shape Key
- Keyframe value to 1.0 at 240 frames
- Mould into new shape
- For large items (x2 clay), scale up by 1.5x and apply transforms
- Export animation:
    - name = ashfall/pot/<shape>_anim.nif
    - Export Flags:
        - Only Selected
        - Export Animations
        - Preserve Material Names
        - Strip Numeric Suffixes
- In Nifskope, change the flags on the controller to clamp mode
# Raw Clay Item
It is essentail that the Normals and base UV mapping are identical to the animation mesh.
- Convert animation to static mesh:
    - Duplicate to new object
    - Move shapekey to first position
    - Object->Apply->Visual Geometry to Mesh
    - Remove keyframes
- Create decal UV Maps
Assign textures and UV maps, and edit UVs as needed:
    Map order:
        - 1: base texture
        - 2: cracks
        - 3: decorations and temper
    Decal order:
        - 1: temper
        - 2: decorations
        - 3: cracks
    - Bottom of cups etc should be projected from view and mapped to bottom third of the texture
- Remove decal textures and export
    - name = ashfall/pot/<shape>_raw.nif
    - Export Flags:
        - Only Selected
        - Preserve Material Names
        - Strip Numeric Suffixes

# Fired Clay Item
- Copy raw clay item to new object
- Change base texture to fired clay
- Fix base UV mapping - use texel map texture and get everything square
- Apply vertex shading
- Export
    - name = ashfall/pot/<shape>_fired.nif
    - Export Flags:
        - Only Selected
        - Preserve Material Names
        - Strip Numeric Suffixes

# Shatter Animation
- Add glaze decal (to make it easier verify the UV mapping is correct later)
- Select fired item (no need to clone first)
- Object->Quick Effects->Cell Fracture
    - Source Limit: 10
- While all generated pieces are still selected: Object->Rigid Body->Add Active
- You may need to copy to a new Blender scene to avoid colliding with invisible pieces
- Add a cube, set to Rigid Body Passive. Slightly raise the item above the cube, then adjust settings until the animation looks good. Increase gravity to speed up the effect
- Set frame range to about 20, or when the pieces have settled
- Object->Rigid Body->Bake to Keyframes
- Select all "interior" faces, separate into new objects, and move into new Empty called "NO_DECALS"
- On root node: Object->Bake Action
    - Create Morrowind keyframes:
        - 1: Idle2: Start
        - 20: Idle: Start, Idle: Stop, Idle2: Stop
- Export animation:
    - name = ashfall/pot/<shape>_break.nif
    - Export Flags:
        - Only Selected
        - Export Animations
        - Extract Keyframe Data
        - Preserve Material Names
        - **DISABLE** Strip Numeric Suffixes - this breaks KFs
- Create raw and fired icons
- Create the following items in the CS:
    - misc: ashfall_<shape>_raw
    - misc: ashfall_<shape>
    - activator: ashfall_<shape>_break
- Create config entry:
{
    name = <shape name>,
    id = "ashfall_<shape>_raw",
    firedItemId = "ashfall_<shape>",
    brokenId = "ashfall_<shape>_break",
    clayAmount = <amount>,
    animationMesh = "ashfall/pot/<shape>_anim.nif",
    craftingMethod = "wheel",
    difficulty = <difficulty>,
    canDecorate = true,
}

## Ashfall Integrations
Edit the fired mesh, adding water meshes etc