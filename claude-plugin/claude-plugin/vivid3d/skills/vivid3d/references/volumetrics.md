# Volumetrics: fog, light shafts, clouds, haze

Engine facts come from `settings_get page:"render"` (category Volumetrics / Clouds / Weather) and `GameLight3D`; the way the pieces combine is guidance to verify with `screenshot`.

## Volumetric fog (froxel volumetric lighting)
Render page, category **Volumetrics**:
| setting | default | meaning |
|---|---|---|
| `VolumetricFog` | off | Master switch (the engine page calls it `VolumetricLighting`: "Froxel volumetric fog / light shafts", the same feature). |
| `VolScattering` | 1 | Scattering scale: overall density/strength of the lit fog. |
| `VolShadowContrast` | 1.85 | How strongly shadows cut the fog (shafts). |
| `VolShadowSoftness` | 0.72 | Softness of the shadowed regions in the fog. |
| `VolShadowFloor` | 0.04 | Minimum fog light kept inside shadow (0 = totally dark shadow volumes). |
| `VolTemporal` | on | Temporal history (smooths noise). |
| `VolTemporalBlend` | 0.07 | How much history blends in (lower = more history/smoother but can ghost when things move). |

Per light: `GameLight3D.EnableVolumetric` (default **off** for lights created from the Create menu or `create_node`). A light only feeds the fog when this is on.

### Recipe: god rays / light shafts through a window or trees (guidance)
1. `settings_set {page:"render", values:{VolumetricFog:true}}`.
2. Select the light that should produce shafts: `set_property {node, component:"GameLight3D", property:"EnableVolumetric", value:true}` and `CastShadows:true` (shafts come from occluded light; the volume uses the light's shadows).
3. Tune `VolScattering` up for thicker haze, `VolShadowContrast` up for more defined shafts, `VolShadowFloor` toward 0 for darker gaps.
4. Add `postprocess/Bloom` for glow and keep exposure sane (postprocess.md). Screenshot at each step; fog that is too dense washes out the scene quickly: change in small steps (VolScattering 0.5-1.5).

### Recipe: moody interior haze (guidance)
`VolumetricFog` on, 1-2 spot or point lights with `EnableVolumetric` and shadows, `VolTemporal` on. Keep the number of volumetric lights small: each adds cost.

## Light shafts from clouds/sky (Clouds category)
`Clouds` (Volumetric Clouds) with `LightShafts` (on by default) and `ShaftStrength` Soft | Medium | Strong | Custom create sun shafts through the cloud layer. See environment-and-weather.md for the cloud settings.

## Rain haze (Weather category)
`VolumeHaze` ("Volume Haze", on by default) with `VolumeStrength` adds atmospheric haze while rain is enabled (`Rain`, `RainPreset`). Rain also has `LensFlecks` (screen flecks).

## Troubleshooting
- No fog visible: `VolumetricFog` off, or no light with `EnableVolumetric`, or intensity/range too low to reach the view.
- Shafts but no defined shadows: the light needs `CastShadows`, and (point lights) a free slot in the shadow budget (shadows.md).
- Flicker/noise: keep `VolTemporal` on, lower `VolTemporalBlend` slightly; heavy `VolScattering` makes noise more visible.
- Performance drop: turn off `EnableVolumetric` on minor lights first, then lower the engine `RenderScale`.
