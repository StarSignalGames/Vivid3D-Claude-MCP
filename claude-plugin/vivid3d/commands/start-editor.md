---
description: Start the Vivid3D editor (asks for the full path to Vivid3D.exe) so the MCP bridge is available
---

Make the Vivid3D editor available to the `vivid3d` MCP server. Follow the "Starting the editor" section of the `vivid3d` skill exactly:

1. If the `ping` tool works, the editor is already running: report its `project`, `currentState` and `processId` and stop. Do not start a second instance.
2. Otherwise ask me for the FULL path of the Vivid3D.exe I want to use. Never guess it, never search the disk for it, and never reuse a path from an earlier conversation without asking me to confirm it.
3. Start it with exactly that path (PowerShell `Start-Process`, working directory = the exe's folder). The bridge is on by default, so no flag is needed.
4. Wait for it to open, then ask me to reconnect the MCP server (`/mcp`) and call `ping` + `project_info` to confirm which project is open.
