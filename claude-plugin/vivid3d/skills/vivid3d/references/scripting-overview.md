# Writing project C# scripts (overview)

Project scripts are plain `.cs` files in the user's project folder. The editor compiles all of them into one in-memory assembly and **hot-reloads about every 2 seconds** after a file changes (not during play). Each script class is one of a small set of kinds, and the kind decides what it *is* in the scene:

| derives from | becomes | how it is placed | lifecycle hooks |
|---|---|---|---|
| `GameNode` (or `GraphNode`) | **a scene node** | `attach_script` creates it (like dropping the file into the scene) | `OnInit`, `OnPlacedInEditor`, `OnPositionedInEditor`, `Update(dt)`, `OnCollisionEntered` |
| `GameComponent` / `NodeComponent` | **a component on a node** (child of the node) | `attach_script {node}` | `OnAttach`, `OnDetach`, `OnUpdate(dt)`, `OnRender` |
| `NodeInteraction` | **an interaction script on a node** (not a child) | `attach_script {node}` | `Clicked`, `DoubleClicked`, `Used`, `Entered`, `Left`, `UpdateInteraction(dt)`, `OnAttach`, `OnDetach` |
| `NodeLogic` | **a logic script on a node** (not a child) | `attach_script {node}` | `OnAttach`, `OnInit`, `OnPlay`, `OnStop`, `OnUpdate(dt)`, `OnDetach` |
| `State` | a game state (`States/*.cs`, first line of `project.info` names the start state) | not attached to scenes | n/a |
| `.rl` files | Resonance script (RlGameNode / RlGameComponent / RlNodeInteraction) | `attach_script` also accepts `.rl` paths | not covered here |

Rule of thumb: "something that exists in the world" = **GameNode**. "Behaviour I add to an existing object" = **NodeInteraction** (reacts to the player: aim/click/use/enter/leave), **NodeLogic** (runs every frame while playing), or **GameComponent** (a component that sits among the node's children, can use `Node`). NodeInteraction is the most common for gameplay objects (doors, pickups, buttons, triggers): read [node-interactions.md](node-interactions.md).

## Workflow
1. Look at the project first: `content_search {pattern:"*.cs"}` / `content_tree {path:"Code"}`; read one or two existing scripts to copy the project's namespaces, folder layout and naming. (The current engine namespaces are `Vivid3D.World`, `Vivid3D.Core`, `Vivid3D.UI`, `Vivid3D.Input` plus `OpenTK.Mathematics`; some older projects still use `Virtual3D.*`: match the project.)
2. Write the file with your normal file tools. **Class name = file name** (`SlideDoor.cs` contains `public class SlideDoor : NodeInteraction`), `public`, non-abstract, with a public parameterless constructor (set `Name = "SlideDoor"` in it).
3. `recompile_scripts`: fix every error it reports (see below), then `list_scripts` to confirm the type is found with the right `kind`. Project scripts are compiled when the 3D Scene Editor opens: from the hub `list_scripts` is empty, so `open_editor` first.
4. `attach_script {script:"SlideDoor", node:"Door", values:{Amount:3}}` (or without `node` for a GameNode). It is undoable and sets the script's public properties.
5. Test: `invoke_interaction`, `play start` (+ `console`, `node_detail`, `screenshot`), `play stop`. Script `Console.WriteLine` and `Log(...)` output appears in the `console` tool.
6. Properties persist with the scene: `scene_io save` writes them into the `.scene` file; they come back on load (verified: a float property survives save/reload).

## Where scripts live
Anywhere under the project folder. Existing projects use e.g. `Code/Interactions`, `Code/Game`, `Scripts/...`. Skipped by the game compile: folders named `bin`, `obj`, `.git`, `.vs`, `temp`, `New folder`, `dorment`, `assets/Materials`. Files under `Editor/`, `EditorWindows/` or `Code/Editor/` are **editor plugins** (compiled only for the 3D Scene Editor, `IEditorWindow` tools), not game scripts. (From reading the code: the exclusion test runs on the full path, so a whole project that sits inside a folder named `temp` compiles nothing.)

## Compile rules and pitfalls
- **One compile error breaks every project script type** (all become "Unknown type"). After each edit: `recompile_scripts`; never leave a broken file behind.
- `recompile_scripts` returns `error` text with `file(line,col): CSxxxx message`; also check `console` for runtime exceptions: callbacks are wrapped in try/catch and logged as `[NodeInteraction] Clicked() threw on X: message` (so a runtime bug does not crash the editor, but the callback silently stops doing its work).
- C# language version is latest, nullable reference types are on, `System`, `System.Linq`, `System.Collections.Generic`, `System.IO`, `System.Text`, `System.Threading(.Tasks)` are implicitly imported. Add `using OpenTK.Mathematics;` for `Vector3` etc.
- Do not use the editor's `FileBrowser` from scripts. Do not block (sleep/wait) inside callbacks: use `InvokeAfter` / `TweenTo` / per-frame state machines.
- Edit mode ticks some updates too (e.g. `GameNode.Update`, component `OnUpdate`): guard play-only logic with `ProjectInfo.CurrentRunMode == RunMode.Playing` (`using Vivid3D.Core;`). `NodeInteraction.UpdateInteraction` and `NodeLogic.OnUpdate` run only while the scene is playing.
- Stopping play reloads the scene from its pre-play snapshot, so instance fields reset: store persistent game state in project systems, not in node scripts.

## Exposing settings in the inspector
Public properties with simple types (bool, int, float, string, enum, `Vector2/3/4`) appear in the Properties panel and are saved with the scene. Decorate with `using System.ComponentModel; using Vivid3D.UI;`:
`[DisplayName("Amount")] [Description("Distance in metres.")] [Range(-10f, 10f)] public float Amount { get; set; } = 1f;`
`[Category("Door")]` groups them; `[Browsable(false)]` or `[HideInEditor]` hides one. For **NodeInteraction/NodeLogic/GameComponent subclasses every public property is shown**; for `GameNode`/`GraphNode` subclasses add `[ShowInEditor]` (or `[UserProperty]`) to the properties you want visible: the Properties panel hides every property without one of them as soon as the type has any such attribute (the engine's own node properties use it).

## Related
- [script-templates.md](script-templates.md): copy-paste starting points for each kind.
- [scripting-api.md](scripting-api.md): the engine API for transforms, alignment, raycasts, physics, queries, input, effects.
- [node-interactions.md](node-interactions.md): NodeInteraction in depth.
- [scripts.md](scripts.md): `exec_csharp` snippets and the compile status tools.
