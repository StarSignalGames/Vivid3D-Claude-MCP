VIVID3D MCP PLUGIN FOR CLAUDE - INSTALL AND USE
================================================

WHAT THIS IS
------------
A Claude Code plugin that lets Claude drive a RUNNING Vivid3D editor: build and
edit scenes, tune lighting / shadows / volumetrics / post-processing, change any
Tools > Settings value, take screenshots, write and attach C# scripts, browse
project files, and operate the editor UI. It also contains a "vivid3d" skill that
teaches Claude how the engine works (scripting, NodeInteraction, lighting, ...).

WHAT IS IN THIS FOLDER
----------------------
  INSTALL.txt              this file
  claude-plugin\           the plugin (a FOLDER, not a single file)
      .claude-plugin\marketplace.json     marketplace listing (what you "add")
      vivid3d\                            the plugin itself
          .claude-plugin\plugin.json
          .mcp.json                       connects Claude to the editor
          bin\vivid-mcp-proxy.ps1         small PowerShell proxy used by .mcp.json
          commands\start-editor.md        /vivid3d:start-editor
          skills\vivid3d\SKILL.md         the engine skill + references\*.md
  claude-plugin.zip        the same folder as one zip, for sharing/uploading

a

REQUIREMENTS
------------
- Claude Code (CLI or the Claude desktop app, Code tab).
- Windows with PowerShell (the proxy is a .ps1 script).
- A Vivid3D editor build that includes the MCP bridge. The bridge is built into
  the editor and is ON by default (listens on 127.0.0.1:8765). Turn it off only
  with the --no-mcp command-line flag (or environment variable VIVID_MCP=0).

INSTALL (ONCE)
--------------
1. Unzip claude-plugin.zip somewhere permanent (or keep the claude-plugin folder
   where it is). Do not install from a temporary folder: Claude reads the plugin
   from where you point it.
2. In a terminal (or in Claude Code, using the /plugin commands):

       claude plugin marketplace add "C:\vivid3d\Vivid3DMCP\claude-plugin"
       claude plugin install vivid3d@vivid3d-local

   Inside Claude Code the same thing is:
       /plugin marketplace add C:\vivid3d\Vivid3DMCP\claude-plugin
       /plugin install vivid3d@vivid3d-local
3. Check it:   claude plugin list      (should show vivid3d  - enabled)
4. Start a NEW Claude session (or run /mcp to reconnect) so the MCP server loads.

UPDATE / UNINSTALL
------------------
  claude plugin marketplace update vivid3d-local     (after you change the files)
  claude plugin uninstall vivid3d@vivid3d-local
  claude plugin marketplace remove vivid3d-local

USE
---
1. Start the Vivid3D editor YOURSELF and leave it running. It is one persistent
   instance (like Blender with its MCP add-on); Claude never closes it.
   On the editor hub, pick your project.
2. Open Claude Code and ask for things, for example:
     "ping the editor and tell me which project is open"
     "open the 3D scene editor and build a 20 x 20 room with three point lights"
     "write a sliding-door NodeInteraction script and attach it to the Door node"
     "find every script that mentions NodeInteraction"
   Claude starts the 3D Scene Editor with a NEW blank scene (floor grid on). It
   only restores your previous scene if you ask for it, and it will not save
   unless you ask.
3. Watch the box at the bottom-left of the editor window: it shows the command
   Claude is running now and the last few. It fades after ~20 seconds idle.

IF THE EDITOR IS NOT RUNNING
----------------------------
Claude will say the editor is not reachable. It will then ASK YOU for the full
path of Vivid3D.exe (it never guesses or searches for it), start it with that
path, and ask you to reconnect with /mcp. You can also run:  /vivid3d:start-editor

HOW IT CONNECTS (FOR THE CURIOUS)
---------------------------------
The editor writes a random token and its address to
    %LOCALAPPDATA%\Vivid3D\mcp.token   and   mcp.endpoint
The plugin's proxy reads those files and forwards Claude's requests to
http://127.0.0.1:8765/mcp. Only programs on your own PC can reach it (loopback)
and every request needs the token. Claude can run C# in the editor, so keep the
bridge limited to your own machine and use --no-mcp when you do not want it.

TROUBLESHOOTING
---------------
- "editor not reachable": start the editor, then /mcp to reconnect. After a
  failure Claude may wait up to ~15 minutes before retrying automatically; /mcp
  retries immediately.
- "unauthorized": the proxy read a different token than the running editor
  uses. This can happen with the Claude desktop app, which runs in a sandbox
  that redirects AppData writes: if Claude itself launched an editor earlier, a
  private copy of the token files may exist at
    %LOCALAPPDATA%\Packages\Claude_*\LocalCache\Local\Vivid3D\
  Delete mcp.token and mcp.endpoint there (they are only copies), keep the real
  editor running, then /mcp.
- Port 8765 already in use: only one editor can own the bridge at a time.
  Close the other editor, or start one with --mcp-port=<number> (then the
  endpoint file tells the proxy where to connect).
- Opening a throw-away project with the editor's project-folder argument
  saves that project as the editor's remembered hub project (editor_config.json
  next to the exe). Use a separate copy of the editor for experiments.
- Project scripts inside folders named temp, obj, bin, .git, dorment or
  assets\Materials are not compiled; keep scratch projects out of Temp folders.
- Settings Claude changes (Tools > Settings) are not undoable; Claude reports the
  old and new values. Scene edits are undoable (Ctrl+Z or the undo tool).

WHAT CLAUDE CAN DO (TOOL OVERVIEW)
----------------------------------
  State/navigation   ping, project_info, console, open_editor, close_editor
  See                screenshot, ui_tree
  Scene              scene_summary, node_detail, create_node (cube, sphere,
                     plane, torus, capsule, pyramid, lights, cameras, ...),
                     move/rotate/scale/look_at/align/place_on_ground, set_property,
                     undo/redo, scene_io (save/load/new), play
  Settings           settings_pages / get / set / apply_preset (every Tools >
                     Settings page, including post-process effects)
  Project files      content_tree, content_search (wildcards, grep inside files)
  Scripts            list_scripts, attach_script, detach_script,
                     invoke_interaction, recompile_scripts, exec_csharp
  UI input           click, drag, scroll, key, type_text

Version 0.1.0
