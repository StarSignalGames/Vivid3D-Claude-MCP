# Working patterns

## Orientation checklist (start of a session)
1. `ping`: editor alive? `currentState` tells you where it is (`SEditorMain` = hub, `S3DEditor` = 3D Scene Editor).
2. `project_info`: `projectPath` is the project the user picked on the hub. Quote it back to the user if anything is ambiguous.
3. Hub -> `open_editor {editor:"3d-scene-editor"}` (blank scene, grid on) or with `scene:"scenes/X.scene"` (path relative to the project, see `project_info.sceneFiles`). Wait a couple of seconds (scene loads are asynchronous: poll `scene_summary` until `rootCount` is non-zero for a scene that has content).

## Seeing
- `screenshot` with no target = whole editor. Target a panel by name: `"3D Scene View"`, `"Properties"`, `"Scene Graph"`, or a `ui_tree` id. Use `maxWidth` 800-1400 to keep images small.
- The 3D Scene View is the picture of the scene. After a lighting/material/post change, capture it. Remember the editor chrome and gizmos are in the picture.
- `ui_tree` is cheaper than an image for finding buttons/fields. Control ids are stable only while the layout is unchanged; re-query after the UI changes.

## Editing safely
- Every scene edit tool is one undo step (multi-node ops too): `undo` / `redo` take `steps`. After a mistake, undo rather than hand-reverting.
- Settings (`settings_set`) are NOT undoable; the response contains `old` values: keep them so you can revert.
- `set_property` handles any editor-visible simple property on a node or on one of its components (`component` = type name, e.g. `GameLight3D`). Use `node_detail` to learn the names.
- Batch related changes in one call where a tool supports it (`settings_set.values`, `align_nodes.nodes`) to keep the editor responsive.

## When something fails
- Tool error text is meant to be read: it names valid options (enum values, component names, pages).
- Check `console` (filter `level:"error"`). Use `since` with the last `latestSeq` to read only new lines.
- "Timed out waiting for the editor main thread": the editor is busy (loading) or minimized. Wait and retry once; do not hammer it.
- A modal dialog in the editor can block input tools: take a `screenshot`, and if a dialog is open, deal with it with `click` (or ask the user).

## Play mode
`play start` -> wait -> `screenshot` / `exec_csharp` to observe -> `play stop`. Stopping restores the pre-play scene. Do not edit while playing.

## Etiquette
The user shares this editor with you. Do not rearrange their panels, change theme/editor preferences, or toggle unrelated settings. Tell them which settings you changed (old -> new).
