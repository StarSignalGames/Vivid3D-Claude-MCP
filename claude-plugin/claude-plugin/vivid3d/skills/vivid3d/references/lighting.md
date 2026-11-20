# Lighting

Source of truth: the `GameLight3D` component and the Render/Engine settings pages. Property names, types and descriptions below come from the engine; **tuning advice is marked as guidance** and must be confirmed with `screenshot`.

## Creating a light
`create_node {kind:"light", lightType:"Point"|"Spot"|"Directional", name, position, rotation}` creates a node with a `GameLight3D` component, the same as the Create menu. Defaults applied by the editor:

| type | Intensity | Range | other |
|---|---|---|---|
| Point | 5 | 20 | omnidirectional |
| Spot | 8 | 25 | InnerAngle 20, OuterAngle 30 |
| Directional | 1.5 | 1000 (unused) | node rotated -45 deg about X (sun-like) |

New lights start with `CastShadows = false` and `EnableVolumetric = false` (shadowless so they are cheap and inspectable). Turn those on deliberately (shadows.md, volumetrics.md). Aim spots/directionals with `look_at` or `rotate_node` (a light shines along the node's forward, -Z).

## Light properties (set with `set_property {node, component:"GameLight3D", property, value}`)
| property | type | meaning |
|---|---|---|
| `Type` | Point / Directional / Spot | Point = omnidirectional, Directional = sun-like, Spot = cone. |
| `Color` | [r,g,b] | Light color. |
| `Intensity` | float | Brightness. |
| `Range` | float | Maximum reach. Not used for Directional. |
| `SourceRadius` | float | Area-light radius (m) for contact-hardening penumbra. 0 = sharp umbra. The engine suggests 0.02-0.08 for a soft rim; larger looks blurry. |
| `InnerAngle`, `OuterAngle` | degrees | Spot cone (inner = full intensity, outer = edge). |
| `HasSpecular` | bool | Specular highlights for this light. |
| `CastShadows` | bool | See shadows.md. |
| `Smooth` | bool | Soft penumbra (Vogel-disk PCF). Off = hard 1-tap. |
| `SoftShadowsQuality` | High / Mid / Low | Filter taps when Smooth is on. |
| `Mobility` | Static / Moving | Static caches the unmoving world into the point-light cube; Moving redraws it because the light can move. |
| `ShadowQuality` | High / Mid / Low / Retro | Shadow density (see shadows.md). |
| `ShadowResolution` | int | Explicit shadow map size. |
| `ShadowBias` | float | Extra receiver bias in meters (directional default 0.005). Raise if you see acne. |
| `EnableVolumetric` | bool | Light contributes to volumetric fog/shafts (volumetrics.md). |
| `AmbientEnabled` | bool | **Directional only**: scene-wide ambient on/off. Off removes ALL ambient (sky/IBL, hemisphere fill and the flat term), so unlit surfaces become 0,0,0. |
| `AmbientColor` | [r,g,b] | **Directional only**: flat ambient term (scaled by albedo and AO) while ambient is on. 0,0,0 = none. |

`node_detail` on the light node shows current values. Use `node` + `component` exactly as above; `property` is case-insensitive.

## What else lights a scene (all on the Render settings page, `settings_get page:"render"`)
- **Environment** (`Environment`: CubeMap | Color | PbrSky), **Image-Based Lighting** (`ImageBasedLighting`), `EnvironmentHdrPath`, `EnvironmentHdrBrightness`, `EnvironmentColor`: see environment-and-weather.md. An outdoor scene is often lit mostly by sky/IBL + one directional light.
- **Soft Shadow Umbra Floor** (`SoftShadowUmbraFloor`): off (default) = fully black umbras unless another light or IBL reaches them; on = deep shadows keep ~12% of the light.
- **Ray tracing** (`RtShadows`, `RtFillLights` "Other Lights Add Light", `RtIndirect`, `RtEnvIntensity`): see raytracing-and-quality.md.
- Emissive materials drive **Emissive Bloom** (postprocess.md).

## Recipes (guidance: verify visually)
- **Daylight exterior:** one `Directional` light, intensity ~1.5, rotated about -45..-60 deg X plus some Y; `CastShadows` on, `Smooth` on; Environment `PbrSky` or an HDR for fill (IBL on). Adjust `AmbientEnabled/AmbientColor` only if shadows are too black.
- **Interior:** a few `Point`/`Spot` lights near the ceiling (range 8-15), warm `Color` e.g. [1,0.85,0.65]; shadows on only for the 1-2 key lights (see the shadow budget in shadows.md); `ImageBasedLighting` still contributes fill.
- **Spotlight/flashlight:** `Spot`, `InnerAngle` 15-20, `OuterAngle` 30-40, `look_at` the target, shadows on, `SourceRadius` 0.02-0.05.
- **Night:** low directional intensity (0.1-0.3, cool color [0.5,0.6,1]) or Environment `Color` dark; several small warm point lights; bloom + volumetric fog add mood.
- **Visibility problems:** a dark scene is usually (1) no light/ambient reaching surfaces (check `AmbientEnabled`, IBL, Environment), (2) tone mapping exposure (postprocess.md), (3) shadow budget starving lights (shadows.md).

Always check the result with `screenshot target:"3D Scene View"`.
