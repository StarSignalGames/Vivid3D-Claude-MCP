# Environment, sky, clouds, weather

All on `settings_get page:"render"` (categories Environment, Lighting, Clouds, Weather). Scene settings (render sheet) apply to the current scene/view; a **new scene** resets them to neutral defaults.

## Environment (what is behind and around the scene)
- `Environment`: **CubeMap** | **Color** | **PbrSky** (procedural physically based sky).
- `ImageBasedLighting` (on): the environment also lights surfaces (ambient/reflections). Turn off only for a deliberately flat/lit-by-lights-only look.
- `EnvironmentHdrPath` + `EnvironmentHdrBrightness` (1): HDR image for CubeMap mode (path relative to the project; use the Content Browser for the file you want, or pick one that exists in `project_info`'s project).
- `EnvironmentColor` [0.12,0.13,0.16 default]: flat color for Color mode.
- `SoftShadowUmbraFloor` (Lighting category): see shadows.md.

## Time of day (sky)
`TimeOfDayPreset` Dawn | Morning | Noon | Afternoon | Dusk | Night | Custom, `TimeOfDayHours` (0-24, default 14), `DayOfYear` (174), `Latitude` (51.5), `Longitude` (0), `PlayRate` (0 = frozen; >0 animates time of day). With `Environment = PbrSky` these position the sun/sky. Whether they also rotate your directional light depends on the scene setup: check with a `screenshot` after changing them and aim the sun light yourself (`rotate_node`/`look_at`) if needed.

## Volumetric clouds
`Clouds` (off), `CloudAmount` Light|Medium|Heavy|Custom, `CloudQuality` Low|Medium|High, `CloudWind` Calm|Moderate|Strong|Custom, `LightShafts` (on), `ShaftStrength` Soft|Medium|Strong|Custom, `CloudSeed` (1337), `CloudCenter` [0,850,0], `CloudHalfExtents` [2000,600,2000] (the cloud volume's box). Quality High costs more.

## Rain / weather
`RainPreset` Off | Drizzle | LightRain | SteadyRain | HeavyRain | Downpour | Thunderstorm | Custom; `Rain` master toggle (off); `RainIntensity` 0.55; `RainWind` [1.8,0,0.4]; `RainStreakDensity`, `RainFallBase`/`RainFallBoost` (fall speed), `RainBoxHeight`; puddles/wetness: `PuddleAmount` 0.85, `PuddleRadius` 176, `PuddleFade`, `WetnessGain`, `WetnessLoss`; `IndoorOcclusion` (on: no rain under cover), `RainSplashes`, `SplashRate`; atmosphere: `VolumeHaze`, `VolumeStrength`; `LensFlecks` + `LensStrength` (drops on the lens). Prefer a preset first, then tune individual values (`settings_get` after setting a preset to see what it changed; verify rather than assuming how presets and manual values interact).

## Recipes (guidance)
- **Clear day:** `Environment=PbrSky`, `TimeOfDayPreset=Noon`, one shadowed directional light, `Clouds` Light.
- **Overcast:** `Clouds` on, `CloudAmount` Heavy, directional intensity reduced, `Smooth` shadows (or off shadows), fog slightly up.
- **Dusk/dawn:** preset Dusk, warm low directional light (low angle, color [1,0.6,0.35]), volumetric fog + shafts, bloom.
- **Storm:** `RainPreset=Thunderstorm`, clouds Heavy, dark Environment, lower light intensity, rain post effects follow automatically.
- **Night:** preset Night (or Environment Color very dark), local lights, volumetric fog for lamps.
