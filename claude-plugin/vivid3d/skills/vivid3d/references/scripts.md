# Project scripts and `exec_csharp`

> Writing script classes (GameNode / GameComponent / NodeInteraction / NodeLogic), attaching them and the engine API are in [scripting-overview.md](scripting-overview.md), [node-interactions.md](node-interactions.md), [script-templates.md](script-templates.md) and [scripting-api.md](scripting-api.md). This file covers compile status and snippets.

## Project C# scripts
The editor compiles the project's `*.cs` files with Roslyn into one in-memory assembly (game scripts; with the 3D Scene Editor also editor-plugin scripts such as `Code/Editor` / `EditorWindows`). It **hot-reloads about every 2 seconds** after a file is added, removed or modified (not during play).
- Edit project files with your normal file tools, then call `recompile_scripts` (forces it now) and read the result: `success`, `error` (compiler messages with file/line), `compiledFiles`. `script_status` shows the last result without recompiling. Also read `console` (`level:"error"`).
- **One compile error breaks every project script type** ("Unknown type" for all of them, not just the broken file). If many things suddenly stop resolving, a compile error is the cause: fix it and recompile before debugging anything else.
- A compile failure also pops an error dialog in the editor. Report the error to the user; do not leave scripts in a non-compiling state.
- Do not use the editor's `FileBrowser` from scripts (known problem in project scripts).
- The scripts directory is the project root (`script_status.scriptsDirectory`).

## `exec_csharp` (run a snippet in the editor process)
Use it when no dedicated tool exists. The code is a method body: statements ending in `return value;`, or a single expression without a semicolon. Provided locals: `Graph` (the scene), `Selected`, `Selection`, `Find(nameOrIdOrPath)`, `Log(obj)`, `g` (`g.Scripts` = ScriptManager). Usings: System, System.Linq/Collections/IO/Text/Threading, OpenTK.Mathematics, Vivid3D.Core, Vivid3D.World, Vivid3D.UI, VirtualEditor. Do not add `using` lines; qualify other names.
- It runs on the main thread (needed for scene/UI/GPU). A long loop freezes the editor: keep snippets short. `background:true` runs on a pool thread for pure computation only.
- The return value is serialized to JSON (nodes become summaries, collections up to 200 items, simple property bags). Compile errors return line numbers relative to your code. Exceptions return the type, message and stack.
- Snippets cannot reference the project's own script types (they are in a separate in-memory assembly); engine and editor types are fine.
- For undoable edits push commands: `HistoryManager.Push(new PropertyChangeCommand(target, propertyInfo, old, new))`, or use `EditorNodeCommands.*` (AddCreatedNode, DeleteNode, ParentNodeUnder, RenameNode, ...). Raw property writes are not undoable.
- Do not call blocking UI (file dialogs, message boxes) from snippets.

Examples
- `Graph.Roots.Select(r => r.Name).ToList()`
- `var n = Find("Cube"); return new { n.Name, p = n.WorldPosition, kids = n.Children.Count };`
- `var n = PrefabGen.CreateSphere(1f); n.Name = "Ball"; n.LocalPosition = new Vector3(0,2,0); EditorNodeCommands.AddCreatedNode(n); return n;`
