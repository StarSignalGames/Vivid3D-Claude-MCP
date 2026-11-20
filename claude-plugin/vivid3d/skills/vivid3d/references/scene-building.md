# Building scenes

## Primitives (`create_node`)
`kind`: `cube`, `sphere`, `plane`, `grid`, `torus`, `capsule`, `pyramid`; plus `transform` (empty), `camera`, `sound`, `fps_controller`, `collision_box`, `water_plane`, `light`.

| kind | size parameters (defaults) |
|---|---|
| cube | `size` = edge length (1) |
| sphere | `radius` (0.5), `segments` (32) |
| plane | `size` = edge length (1) |
| grid | `size` (6), `segments` (16) |
| torus | `radius` = major (0.8), `tubeRadius` (0.2) |
| capsule | `radius` (0.3), `height` (1) |
| pyramid | `size` = base width (1), `height` (1) |

**Sizes are stored as the node's scale.** A scene file saves a primitive only as its type + transform, and the engine rebuilds the mesh at its DEFAULT size whenever a scene is loaded or play stops. `create_node` therefore bakes `size`/`radius`/`height` into `LocalScale` (cube edge 1, sphere radius 0.5, plane edge 1, torus 0.8/0.2, capsule radius 0.3 + cylinder 1.0, pyramid 1x1 are the base meshes) and an explicit `scale` multiplies that. If you build primitives any other way (e.g. `exec_csharp` with `PrefabGen.CreateSphere(2f)`), set the node scale instead of mesh parameters, or the size is lost on reload. Mesh detail (`segments`) cannot be changed.

Also: `position` [x,y,z], `rotation` Euler degrees, `scale` [x,y,z], `name`, `parent`. A new node is selected. Without `position`, primitives spawn in front of the editor camera projected to the ground (y = 0); with `position` the exact value is used.

Mesh bounds are about the pivot at the mesh center (a default sphere of radius 2 centered at y=0 spans y -2..2). To rest something on the floor use `place_on_ground` (default mode `bounds`: the bottom of the mesh bounds goes to `groundY`, default 0).

## Non-uniform shapes
Cubes and planes scaled by `scale` make walls, floors, slabs, steps: a 10 x 3 x 0.2 wall is `kind:"cube", scale:[10,3,0.2]`. Position by center: a wall 3 tall standing on y=0 needs center y = 1.5 (or create it then `place_on_ground`).

## Moving things
- `move_node`: `delta` (relative) or `to` (absolute), `space` = `world` (default) | `parent` | `self` (along the node's own rotated axes; delta only).
- `rotate_node`: `euler` (relative, degrees) with `space` `self` (default) | `world`, or `to` (absolute local Euler).
- `scale_node`: `factor` (multiply; number or [x,y,z]) or `to` (absolute).
- `look_at`: point the node's forward (-Z) at a node or world point (lights, cameras, spotlights).
- `align_to_node`: copy another node's world position/rotation (optional `offset`, `scale:true` to copy scale).
- `align_nodes`: `axis` x|y|z, `mode` min|center|max (align to the group's bounds, or to `value`) or `distribute` (even spacing, 3+ nodes).
- `get_bounds`: world min/max/center/size of a node (mesh + descendants): use it to place things relative to each other instead of guessing sizes.
- `reset_transform`: `parts` position/rotation/scale.

## Hierarchy
`reparent_node` keeps the world transform; omit `parent` to make a node a root. Use `transform` nodes as groups/pivots. Folder structure in the Scene Graph follows the hierarchy.

## Recipe: simple room
1. `create_node cube name:"Floor" scale:[12,0.2,12] position:[0,-0.1,0]`
2. Four walls: cubes with `scale:[12,3,0.2]` at z=±6 and `scale:[0.2,3,12]` at x=±6, y=1.5 (use `get_bounds` on the floor to verify the corner alignment).
3. Group: `create_node transform name:"Room"`, `reparent_node` each piece under it.
4. Light it (see lighting.md), `screenshot`.

## Recipe: row of evenly spaced objects
Create N copies (`duplicate_node` offsets slightly; `move_node` them), then `align_nodes mode:"distribute" axis:"x"`, then `align_nodes mode:"min" axis:"y"` so they share the same base.

## Names
Give nodes meaningful, unique names: later tools resolve by name (first match, depth-first), ids are exact.
