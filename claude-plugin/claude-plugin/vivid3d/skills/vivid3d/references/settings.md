# Tools > Settings: complete map

`settings_pages` lists every page live (with category counts); `settings_get {page, category?, filter?, limit?}` returns each setting with category, description, type, enum options, min/max and current value; `settings_set {page, values:{Name:value,...}}` changes them (name or the on-screen display name, case-insensitive); `settings_apply_preset {effect, preset}` applies post-process presets. These are the same objects the Settings window edits, so you can change **every** setting that window offers.

| page id | window group | what it holds | persistence |
|---|---|---|---|
| `render` | Render | Shadows cache, Ray Tracing, Environment, Lighting, Clouds, Weather, Post Processing (GTAO, emissive bloom), Volumetrics, Performance (MSAA, half-res, upscaler, render scale), Culling, **Viewport (Show Floor Grid)** | scene/renderer state; marks the scene dirty |
| `flux_lod` | Flux LOD | Flux LOD enable and quality | editor config |
| `global` | Global | Display HDR (enable, output mode, nits, UI brightness) | editor config (saved on change) |
| `engine` | Engine | Graphics preset, display/resolution (standalone builds), textures, shaders, shadow quality, AA, upscaling, bloom/lens flare quality, volumetric lighting, threading, culling, diagnostics, shadow budget | saved to the project's engine settings on change |
| `editor` | Editor | Editor camera speed | editor settings (saved on change) |
| `project` | Project | Game global class, branding (splash, icon, product name, intro video, cursor), build (compress, encrypt) | project settings (saved on change) |
| `scene` | Scene | Scene name/scenario, HUD, conversation UI, start event (the current scene) | in the scene file: save to keep |
| `gui` | GUI | In-game GUI theme and font | in the scene file: save to keep |
| `postprocess/<effect>` | Post Processes | Per-effect parameters, `Enabled` toggle, presets | renderer state |

Notes
- `scene` and `gui` need a loaded scene; `postprocess/*` pages exist only for effects present on the current view.
- Settings changes are not on the undo stack. The response lists `old` and `new`; keep the olds to revert.
- Properties with types the JSON API cannot express (e.g. image/texture references such as `SceneImage`) are listed under `unsupported` in `settings_get`: set those through the editor UI (`click`/`drag`) or `exec_csharp`.
- Project settings (`project` page) change how builds look and are written to the project: confirm with the user before changing branding/build values.
- Floor grid: **`render` page, category Viewport, `ShowFloorGrid`**. New scenes opened with `open_editor` / `scene_io new` turn it on automatically.
- Rendering topics: lighting.md, shadows.md, volumetrics.md, postprocess.md, environment-and-weather.md, raytracing-and-quality.md.
