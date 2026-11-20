# Vivid3D Claude plugin (local)

Lets Claude drive a **running** Vivid3D editor (scenes, lighting, settings, scripts, screenshots, UI) over the editor's built-in MCP bridge, with a skill that teaches the engine.

```
claude-plugin/
  .claude-plugin/marketplace.json     local marketplace listing the plugin
  vivid3d/
    .claude-plugin/plugin.json
    .mcp.json                         stdio server = bin/vivid-mcp-proxy.ps1
    bin/vivid-mcp-proxy.ps1           forwards MCP to http://127.0.0.1:8765/mcp with the editor's token
    commands/start-editor.md          /vivid3d:start-editor (asks for the full path to Vivid3D.exe)
    skills/vivid3d/SKILL.md           how to work + index of references/
    skills/vivid3d/references/*.md    lighting, shadows, volumetrics, post-processing, environment, ray tracing,
                                      settings, scene building, scripting (nodes, components, interactions), API
```

## Install (local, nothing is published)
In Claude Code (CLI or desktop app Code tab):
```
/plugin marketplace add C:\GameProjects\Vivid3D\Tools\claude-plugin
/plugin install vivid3d@vivid3d-local
```
(The folder layout follows the Claude Code plugin docs: manifest in `.claude-plugin/plugin.json`, `.mcp.json` and `skills/` at the plugin root, a marketplace at `.claude-plugin/marketplace.json`. If the exact command spelling differs in your version, `/plugin` shows the marketplace/install options.)

## How it connects
- The editor starts the MCP bridge itself (on by default; `--no-mcp` or `VIVID_MCP=0` turns it off) on `127.0.0.1:8765`, bearer-token protected. The token is generated once and kept in `%LOCALAPPDATA%\Vivid3D\mcp.token` (the endpoint in `mcp.endpoint`), so the plugin needs no configuration.
- The plugin never starts or stops the editor. If the editor is not running, tools report that and Claude asks you for the full path of `Vivid3D.exe` (it will not guess), starts it with that path, then you reconnect with `/mcp`.
- Which project is open is whatever you picked on the editor hub: `project_info` reports its full path.
