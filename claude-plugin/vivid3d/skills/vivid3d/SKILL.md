---
name: vivid3d
description: Work inside a live, running Vivid3D engine editor through its MCP tools. Use whenever the user wants to build, inspect or change a Vivid3D scene (primitives, transforms, lights, cameras), tune lighting, shadows, volumetric fog/light shafts, clouds, weather, post-processing, ray tracing or any Tools > Settings value, check how something looks (screenshots), write or debug project C# scripts, or operate the editor UI.
---

# Vivid3D editor control

You are connected to ONE persistent Vivid3D editor process (like Blender with its MCP add-on). It keeps running between tasks; never shut it down or restart it unless asked. Every tool runs on the editor's main thread, so the user sees what you do live and can interrupt or undo.

## Golden rules
1. **Know the project first.** Call `project_info` (full project path, current editor, current scene, scene files) before touching files, and again whenever the user may have switched projects on the hub. Never assume a project.
2. **Look before you change.** `scene_summary` / `node_detail` / `settings_get` first; never guess names, ids or values. Check with `screenshot` after visual changes.
3. **Prefer dedicated tools** over `exec_csharp`. Dedicated tools are undoable and keep the Scene Graph / Properties panels in sync.
4. **Never save, delete scenes/files, or discard unsaved work unless the user asked.** `scene_io` refuses to lose unsaved changes unless `discardChanges=true`: only pass that when the user said so.
5. **New scenes, not the old one.** `open_editor` for the 3D Scene Editor starts a blank scene (floor grid on) and does NOT restore the previous scene unless you pass `scene='last'` or a `.scene` path. Do not use `last` unless the user asks.
6. **Stop play before editing.** Edits during play are discarded; the tools refuse them.
7. Read `console` after anything that might fail (script compile, scene load, settings). It includes script `Console.WriteLine`/`Log` output.
8. The user sees an **activity overlay at the bottom-left of the editor** listing your running command and the last few (it fades about 20 s after you stop). It never appears in your own `screenshot`s. Keep calls purposeful: every call is visible to them.

## Starting the editor
The editor is started by the user. If tools fail with "not reachable" (or `ping` fails):
- Do **not** guess or search for an install path. **Ask the user for the full path of the `Vivid3D.exe` they use** (and confirm it if you remember one from earlier: it may have changed).
- With that exact path: `Start-Process -FilePath "<path>" -WorkingDirectory "<its folder>"` (PowerShell). The bridge is on by default (opt out only with `--no-mcp`).
- The editor opens on the hub; the user picks the project there (or pass a project folder as a positional argument if they tell you which). Then ask them to reconnect the MCP server (`/mcp`) and call `ping` + `project_info`.
- If the editor is already running (`ping` works), use it; never start a second instance (the port 8765 is single-owner).

## Tool map
- **State/navigation:** `ping`, `project_info`, `console`, `list_editors`, `open_editor` (hub cards: 3d-scene-editor, material-editor, ...), `close_editor`.
- **See:** `screenshot` (window or any control; set `maxWidth`), `ui_tree` (controls with ids/bounds/text; ids like `d.0.0.1.0.0` feed `screenshot`/`click`).
- **Scene read:** `scene_summary`, `node_detail`, `get_selection`, `get_bounds`.
- **Scene edit (undoable):** `create_node`, `delete_node`, `rename_node`, `reparent_node`, `duplicate_node`, `select_nodes`, `set_transform`, `move_node`, `rotate_node`, `scale_node`, `look_at`, `align_nodes` (align/distribute), `place_on_ground`, `align_to_node`, `reset_transform`, `set_property`, `undo`, `redo`.
- **Scene/play:** `scene_io` (save/load/new), `play` (start/stop/pause/resume/status).
- **Settings (all of Tools > Settings):** `settings_pages`, `settings_get`, `settings_set`, `settings_apply_preset`.
- **Project files (Content Browser data):** `content_tree` (browse folders level by level with counts/types), `content_search` (wildcards `*` `**` `?`, `|` for several patterns, filter by `type` and `path`, optional `text` grep inside scripts/json/events).
- **Project scripts:** `list_scripts` (what script classes exist and what kind), `attach_script` (puts a script where its type belongs: GameNode -> new scene node; NodeInteraction/NodeLogic/GameComponent -> onto a node), `detach_script`, `invoke_interaction` (fire Clicked/Used/Entered/Left to test), `set_property` with `interaction`/`logic`/`component` to tune attached scripts, `recompile_scripts`, `script_status`.
- **Code snippets:** `exec_csharp` (run C# in the editor when no tool fits).
- **UI input (like a user):** `click`, `mouse_move`, `drag`, `scroll`, `key`, `type_text`. Prefer dedicated tools; use input only for things no tool covers. `click` accepts a control id, name, type, window title or visible label text.

## Conventions
Y is up. A node's forward is -Z. Rotations are Euler **degrees** (`rotation`/`euler`). Distances are world units (meters). `set_transform`/`create_node` positions are local to the parent. Nodes are addressed by id (StableId), path (`scene/A/B`) or name.

## Typical loop
`project_info` -> `open_editor` (if needed) -> build with `create_node` + transform tools -> `screenshot` -> adjust -> `console` for problems -> report what changed. Only `scene_io save` when asked.

## Reference files (read the one that matches the task)
- [workflow.md](references/workflow.md): efficient working patterns, screenshots, verification, undo, failure handling.
- [scene-building.md](references/scene-building.md): primitives, sizing, walls/floors, placement, alignment recipes.
- [lighting.md](references/lighting.md): light types and every light property, recipes (sun, interior, spot, night).
- [shadows.md](references/shadows.md): shadow settings per light, quality tiers, the shadow budget gotcha, acne/softness fixes.
- [volumetrics.md](references/volumetrics.md): volumetric fog, light shafts, clouds, rain haze, recipes.
- [postprocess.md](references/postprocess.md): tone mapping, bloom, lens flare, SSR, motion blur, GTAO, depth of field.
- [environment-and-weather.md](references/environment-and-weather.md): sky, HDR/IBL, time of day, clouds, rain.
- [raytracing-and-quality.md](references/raytracing-and-quality.md): ray tracing setups, quality/performance, upscaling, MSAA, culling.
- [settings.md](references/settings.md): the full Tools > Settings map (pages, where each thing lives, persistence).
- [scripting-overview.md](references/scripting-overview.md): **writing project C# scripts**: which base class becomes a scene node vs attaches to a node (GameNode / GameComponent / NodeInteraction / NodeLogic), workflow, compile rules, inspector properties.
- [node-interactions.md](references/node-interactions.md): **NodeInteraction in depth** (Clicked/Used/Entered/Left/UpdateInteraction, node flags, aiming, trigger volumes, patterns, gotchas, test recipe). Read this before writing any door/button/pickup/trigger.
- [script-templates.md](references/script-templates.md): tested copy-paste templates for every script kind.
- [scripting-api.md](references/scripting-api.md): engine API for transforms, alignment, raycasts, physics, queries, timing, input, effects.
- [scripts.md](references/scripts.md): compile/hot-reload status tools and `exec_csharp` rules.
