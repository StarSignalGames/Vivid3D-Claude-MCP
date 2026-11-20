# Post-processing

How to find what exists: `settings_pages` lists every post-process effect on the current view as `postprocess/<name>` with its `enabled` state and preset names. Read one with `settings_get {page:"postprocess/Bloom"}`; change it with `settings_set {page:"postprocess/Bloom", values:{Enabled:true, Intensity:0.9}}`; apply a preset with `settings_apply_preset {effect:"Bloom", preset:"Soft Sci-Fi"}`. The effect list depends on the view/scene (open the 3D Scene Editor first). All values below are real defaults/ranges from the engine; recipes are guidance.

## Tone mapping: `postprocess/ACES Tone Mapping`
`Preset` Natural | Vivid | CinematicCool | GoldenHour | DarkAndMoody | BleachBypass | Custom (a named look that sets Exposure, Contrast, Saturation), `Exposure` (1 = neutral; >1 brightens, <1 darkens), `Contrast` (1 neutral; <1 washes out, >1 punches mid-tones), `Saturation` (1 neutral, 0 grey). **First stop for "the scene is too dark/bright/flat".** Change Exposure before changing light intensities.

## Bloom: `postprocess/Bloom`
Bloom: `Threshold` 0.9, `SoftKnee` 0.4 (fraction of threshold; lower = sharper cut), `Intensity` 0.85, `Scatter` 1.15 (higher = wider glow), `ClampMax` 30 (per-channel clamp, 0 = off, reduces fireflies), `Tint` [1,1,1]. Anamorphic: `AnamorphicIntensity` 0.3 (0 = off), `AnamorphicStretch` 0.75, `AnamorphicTint` [0.55,0.55,1].
Presets: Soft Sci-Fi, Tactical Soft, Arcade Neon, Subtle Glow, Soft Cinematic, High Contrast, Dreamy, Overbright.
Separate **emissive bloom** lives on the render page (category Post Processing): `EmissiveBloom` (on), `BloomIntensity` 1.35, `BloomBlurRadius` 3.5, `BloomPasses` 3, `BloomBoost` 1.8, `BloomThreshold` 0.05. The engine page has `BloomQuality` Off|High|Mid|Low which scales both.

## Lens flare: `postprocess/Lens Flare`
Many parameters in categories Lens Flare (`Threshold` 0.85, `SoftKnee`, `Intensity` 0.75 [0..10], `FlareColor`, `LargeSourcesOnly` on, `MinSourceSize`), Ghosts (`GhostCount` 3, `GhostScale`, `HaloRadius`, `HaloThickness`, multipliers, `Vignette`), Optical (`ChromaticAberration` 0.07, `SpectralStrength`, `DirtIntensity`, `StarburstIntensity`), Streaks (`StreakIntensity` 0.35, `StreakLength`, `StreakOrientation`, `StreakColor`), Iris (`EnableIris`). Dozens of presets (Classic Ghosts, Studio Default, Cinematic ones, Anamorphic Blue, Golden Hour, Vintage Film, ...): start from a preset, then tweak a few values. Engine page `LensFlareQuality` Off|High|Mid|Low scales it (default Off).

## Screen-space reflections: `postprocess/Cinematic SSR`
`Intensity` 1, `MaxSteps` 300 [1..512], `Thickness` 0.5, `DebugMode`. Ray-traced reflections (raytracing-and-quality.md) are a separate, higher-quality path.

## Motion blur: `postprocess/Cinematic Motion Blur`
`ShutterAngle` 0.5 (= 180 degrees, cinematic), `SampleCount` 64, `Strength` 1 (clamped 0-4), `DebugMode` (Off, Velocity, NeighborMax, ...). Mostly visible in play mode or camera motion.

## Ambient occlusion (render page, category Post Processing)
`Gtao` (off by default), `GtaoRadius` 1.25, `GtaoIntensity` 1, `GtaoQuality` 1. Adds contact darkening in corners/creases: turn on for interiors and grounded objects.

## Depth of field (per camera)
On the camera node's `CameraComponent`: `EnableDepthOfField`, `FocusDistance` (m, sharpest), `FocusRange` (smaller = thinner focal plane), `MaxBlurSize` (px at half res, bokeh size), `DoFIntensity` (0..1), `DoFSampleCount`. Also `FieldOfView` (vertical degrees), `NearPlane`, `FarPlane`.

## Weather post effects
`Rain Puddles`, `Rain Volume`, `Rain Lens Flecks` are driven by the Weather settings (environment-and-weather.md), not by their own parameters.

## Recipes (guidance)
- **Cinematic look:** ACES `Preset` CinematicCool or GoldenHour, Bloom preset Soft Cinematic, `GTAO` on, subtle lens flare preset (Subtle Photographic), camera DoF if there is a clear subject.
- **Neon/sci-fi:** Bloom `Arcade Neon`, emissive materials, `EmissiveBloom` on, Anamorphic bloom up.
- **Flat/washed out:** ACES `Contrast` up (1.1-1.2) and `Saturation` up slightly before touching lights.
- **Too blown out:** lower ACES `Exposure` or Bloom `Intensity`/raise `Threshold`; check emissive intensity.
Capture before/after screenshots when you change several things.
