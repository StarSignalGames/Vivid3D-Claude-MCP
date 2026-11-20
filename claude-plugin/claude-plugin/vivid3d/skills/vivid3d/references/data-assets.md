# JSON data assets: author the FILES, don't click through the UI

Many editor assets are plain JSON files in the project: **cinematics (.cine), events (.event), conversations (.conv), UI layouts (.ui), blend spaces (.blendspace.json), particle FX (.particlefx.json)** and others. When a task creates or edits one of these, **write or edit the JSON file directly** with your file tools, check it, and then use it in the editor/scene. Do not rebuild it by driving the editor UI (clicks, drags, typing into timelines/designers): that is slow, fragile and unnecessary.

## The workflow (always)
1. **Find examples and conventions:** `content_search {pattern:"*.event"}` (or `.cine`, `.ui` ...), read one or two real files from the project, copy their folder layout, naming and style. `asset_types` shows what formats exist and how many files the project has.
2. **Get the exact structure from the engine** (never guess keys, enum numbers or `$type` names):
   - `asset_template {type, ...}`: a correct default JSON (one cinematic track, one event action, one UI control, ...). Copy it into your file and edit values.
   - `asset_schema {type, types?:[...]}`: property names, types, defaults, enum tables, polymorphic variants.
   - `ui_controls {filter}`: valid UI control classes for `.ui`.
3. **Write the file** with the Write/Edit tool into the project (UTF-8 **without BOM**: the Write tool does this; PowerShell 5 `Set-Content -Encoding utf8` adds a BOM that the engine's loaders reject).
4. **`asset_validate {path}`** and fix every error until `ok:true`. It checks syntax (line/column), structure against the engine's own model (wrong types, bad enums, missing `$type`, vector shapes, **unknown or wrongly-cased keys the loader silently ignores**), the engine loader itself, referenced files that don't exist, referenced scene nodes, event branch labels, and for `.ui` unresolved control types/properties. For events read `stats.actionList`: it prints what each numeric `Type` really means.
5. **Use it** (below), look at the result (`asset_preview` for `.ui`, `screenshot`, `console`), iterate on the file (not the UI).

## What each format is and how it is used
| asset | file | used by / how to apply it |
|---|---|---|
| Event | `.event` | `run_event {path}` to test; wired in via the node interaction `NodeInteractionEvent` (property `EventPath`), the scene setting **StartEvent** (`settings_set {page:"scene", values:{StartEvent:"content/events/x.event"}}`), another event's `StartEvent` action, a conversation node's `PreEvent`/`PostEvent` |
| Cinematic | `.cine` | an event action **PlayCinematic** with `CinematicPath`; or a `cinematic` track inside another `.cine` |
| Conversation | `.conv` | an event action **StartConversation** with `ConversationPath`; needs the scene settings **SceneHud** and **ConversationUI** (`.ui` files, `settings_set page:"scene"`) |
| UI layout | `.ui` | scene settings **SceneHud** (HUD) / **ConversationUI**; event actions **ShowUI/HideUI** (`ObjectPath` = a control NAME in the HUD); preview with `asset_preview` |
| Blend space | `.blendspace.json` | `GameNode.SetBlendSpace(path)` / BlendSpaceComponent |
| Particle FX | `.particlefx.json` | a ParticleFXNode (`FxAssetPath`), `CurrentScene.PlayFX(path, pos)`, events BeginParticleFX/StopParticleFX |
| Scene | `.scene` | `scene_io {action:"load", path}`; prefer the scene tools for edits (large editor-owned JSON) |
Project-defined formats (`.quest.json`, `.aiorders.json`, `.site.json`, `.mission.json` ...) are defined by that PROJECT's scripts: `content_search {text:"quest", type:"script"}` finds the loading class; follow its model; `asset_validate` still checks JSON syntax and referenced files.

## Format gotchas (these differ per format, the tools know them)
- **Enums**: `.cine` and `.event` store enums as **numbers** (e.g. `"Type": 16` = PlayCinematic); `.particlefx.json` uses camelCase **strings**; `.ui` property enums are **strings** (`"VerticalAnchor":"Bottom"`). Get numbers from `asset_template`/`asset_schema` enums, never from memory: inserting enum values shifts the numbers.
- **Case**: `.event` and `.conv` property names are **case-sensitive** (a wrongly-cased key is silently ignored, giving defaults); `.cine`, `.blendspace`, `.particlefx` are case-insensitive. `.ui` property names are matched exactly.
- **Vectors** are arrays: `[x,y]`, `[x,y,z]`, `[r,g,b,a]`.
- **Unknown keys are ignored**, never an error at load time: only `asset_validate` tells you about typos.
- **Paths** are project-relative with `/` (older files may contain `\\`); a missing file is only a warning in validation because some resources live in engine content.
- Editor-written files carry noise you can omit when writing by hand (e.g. cinematic keyframes include `StableId`, `WorldPosition`, ...); keep only what you need, the loader fills defaults.

## Events (`.event`)
```json
{ "EventID": "intro", "Description": "What this event does.",
  "Actions": [
    { "Name": "Fade in", "Type": 12, "Duration": 1.5 },
    { "Name": "Play intro", "Type": 16, "CinematicPath": "content/cines/Intro.cine" },
    { "Name": "Talk", "Type": 7, "ConversationPath": "content/convs/Hi.conv" },
    { "Name": "Log", "Type": 43, "VariableValue": "done" } ] }
```
Numbers above are illustrative: **always take them from `asset_template {type:"event", action:"<Name>"}`**. Actions run in order and wait for blocking ones (Wait, FadeIn/Out, PlayCinematic, StartConversation, StartEvent, DisplayText, WaitUntil...) unless `DoNotWait` is true. Parameters that matter per action (from the engine): PrintLog `VariableValue`; Wait/FadeIn/FadeOut/ShakeCamera `Duration`; PlayCinematic `CinematicPath`; StartConversation `ConversationPath`; StartEvent/StopEvent `EventPath`; OpenScene/ChangeMap `ScenePath`; PlayMusic `MusicPath`+`Volume`; PlaySfx `AudioPath`; PlaySfxAt `ObjectPath`+`AudioPath`+`MaxDistance`; ShowUI/HideUI `ObjectPath` (control name); DisplayText `DisplayText`+`Position`+`Color`+`FontSize`+`FadeLeftToRight` (stays until ClearDisplayText); ActivateObject/DeactivateObject/DestroyObject/SetNodeActive `ObjectPath` (+`RegisterBoolValue` for SetNodeActive); UseInteraction `ObjectPath`+`InteractionMode`; EnableInteraction `ObjectPath`+`InteractionEnabled`; PlayAnimation `ObjectPath`+`Value` (clip name); SetLight `ObjectPath`+`RegisterBoolValue`(on/off)+`RegisterFloatValue`(intensity)+`Color`; SpawnPrefab `PrefabPath`+`Position`; registers (Set/Toggle/Add/Remove/CompareAndSet/Copy/WaitUntil) `VariableName` + `RegisterType` + `Register*Value`; branching: a `BranchLabel` action defines a label, `Branch`/`GotoLabel`/`BranchIf` jump to `BranchLabel` (`BranchIf` also uses `VariableName`, `BranchCondition`, `VariableValue`, `InvertCondition`); CustomEvent runs a project `CustomEvent` class (`CustomEventClass` + `CustomProperties`). Children actions go in `Children`.

## Cinematics (`.cine`)
Root: `Name`, `Duration` (seconds), `AutoDuration`, `IsLooping`, `CanBeSkipped`, `PlaybackSpeed`, `Markers[]`, `Tracks[]`. Each track has `"$type"` (camera, node3d, camerashot, audio, sound3d, narration, text, screencolor, postprocess, particle, particleoneshot, skeletal, video, script, gameevent, event, time, sprite, cinematic, float/vec2/vec4) plus `Name`, `IsEnabled/IsMuted/IsSoloed/IsLocked`, `TrackColor` and its own `Keyframes[]` (`Time` seconds, `Easing` number, and a `Value` shaped by the track kind).
- `asset_template {type:"cine", track:"node3d"}` etc. gives each track's exact shape; `asset_schema {type:"cine", types:["Cine3DNodeTrack","CineCameraTrack", ...]}` lists keyframe value fields.
- A `node3d` track animates a scene node by `NodeName` (and optionally `ActivateCamera:true` for camera nodes); keyframe `Value` = `{ "Position":[x,y,z], "EulerRotation":[x,y,z] (degrees), "Scale":[x,y,z] }` (editor files also store `RotationQuat`; if you provide it keep it consistent with `EulerRotation`, or omit and verify).
- **A `node3d` keyframe's `Scale` REPLACES the node's scale while the track plays**: always copy the node's real scale (`node_detail`) into every keyframe, otherwise a sphere scaled 2.0 in the scene snaps to scale 1 during the cinematic. Same for `Position`/rotation: keyframes are absolute poses, not offsets. For smooth rotation keep neighbouring `RotationQuat`s in the same hemisphere (flip the sign of a quaternion whose dot product with the previous one is negative) and make Euler yaw monotonic (0, 90, 180, 270, 360 rather than wrapping to -90).
- Build a camera move by creating the camera node in the scene first (`create_node kind:"camera"`, give it a name), then reference it by `NodeName`; get real positions with `get_bounds`/`node_detail`.
- **Easing is a creative choice per keyframe segment** (Linear, Ease In/Out/InOut in Quad/Cubic/Sine/Expo, Step, Hold; `Easing` on a key shapes the move to the NEXT key). Do not use one curve everywhere: see the table in the `cinematic-checks` skill ("Choosing easing creatively").
- **After creating or editing a cinematic, offer the `cinematic-checks` skill**: ask the user whether they want it inspected; on yes run `cinematic_frames` (one screenshot per 0.5 s) and study every frame for colour clashes and invisible text.
- Chain cinematics with a `cinematic` track (`.cine` paths) or play them from an event with PlayCinematic. Cinematics play inside the running scene: `play start`, `run_event` the event that plays it, then `screenshot`.

## Conversations (`.conv`)
`{ "ConversationID": "id", "RootNode": { "ShortText", "LongText", "Duration", "AudioDuration", "AudioPath", "SpeakerImagePath", "ActorNode", "PreEvent", "PostEvent", "Choices": [ <nodes...> ] } }`: a tree: the player's reply buttons are the `Choices` of the current node; a node without choices ends/continues. `ActorNode` = scene node name speaking, `PreEvent`/`PostEvent` = `.event` paths. Shown through the scene's `ConversationUI` layout, which must contain the controls the conversation runtime fills (look at an existing project's ConversationUI `.ui`: e.g. `ConversationText`, `SpeakerImage`, `Reply1..Reply3`).

## UI layouts (`.ui`)
`{ "ReferenceResolution":[1920,1080], "UseOpacity":false, "Opacity":1, "Roots":[ {"Type":"Vivid3D.UI.IButton","Name":"StartButton","Properties":{...},"Children":[...]} ] }`. `Type` = a control class (full name `Vivid3D.UI.IButton`, or a short name, or a project class); `Properties` = that control's public simple properties (`Position`, `Size`, `Text`, `TextScale`, `TextColor`, `HorizontalAnchor`/`VerticalAnchor` (`Left|Center|Right|Stretch`, `Top|Center|Bottom|Stretch`), `IsVisible`, ...). Positions/sizes are in reference-resolution pixels and scale to the output. Use `asset_template {type:"ui", control:"IButton"}` for a control's properties and defaults, `ui_controls` to list classes. **Always `asset_preview {path}`** after writing: it renders the layout to a PNG so you can check placement and text.
To show it in a scene: `settings_set {page:"scene", values:{SceneHud:"content/UI/Menu.ui"}}` (then `scene_io save` if the user wants it kept), or `ConversationUI` for conversation layouts.

## Applying a change safely
- You edit files in the user's project: tell them which files you created/changed (paths). Never delete or overwrite existing assets without being asked; create new files or edit the one requested.
- After editing a file that is already loaded, reload it: `scene_io load` for scenes. Events and cinematics may be cached by the engine while a scene is playing (it preloads them): if a run shows old behaviour, `play stop`, then `play start` and run it again.
- If the engine behaves differently from what the file says, read `console` (loader errors are printed there) and run `asset_validate` again.
