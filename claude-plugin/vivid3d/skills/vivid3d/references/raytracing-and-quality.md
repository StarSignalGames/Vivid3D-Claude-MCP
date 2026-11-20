# Ray tracing, quality and performance

Settings pages: `render` (Ray Tracing, Performance, Culling) and `engine` (Graphics, Anti-Aliasing, Upscaling, Budget, ...). Read with `settings_get`; names below are exact.

## Ray tracing (render page, category Ray Tracing)
- **Presets:** `RaytracingSetup` = Custom | Default | SharpMirrors | InteriorArchviz | ExteriorArchviz | GlossyMetals | BrushedMetal | WetSurfaces | ProductStudio | Cinematic | SoftIndirect | NightMood | StylizedClean | Performance | HighQuality | RawNoisy. Setting a named setup applies a bundle of values (setting `Custom` does nothing: change an individual value to become Custom). `ReflectionQuality` = Custom | LookingGlass | Polished | ClearCoat | Satin | Brushed | Frosted.
- **Toggles (defaults on):** `RtReflections`, `RtBillboardReflections`, `RtShadows`, `RtFillLights` ("Other Lights Add Light"), `RtDielectric`, `RtSkyboxReflections`, `RtDenoise`, `RtFirefly`, `RtTemporal`, `RtAntiAliasing`, `RtDistanceAa`, `RtWater`, `RtWaterHybridSsr`.
- **Numbers:** `RtBounces` 2, `RtMaxDistance` 10000, `RtShadowBias` 0.01, `RtRoughnessScale/Bias` 1/0, `RtMetallicScale/Bias` 1/0, `RtReflectionSoftness` 0, `RtMetallicMin` 0, `RtIndirect` 1 (indirect scale), `RtEnvIntensity` 0.4, `RtDenoisePasses` 4, `RtFireflyThreshold` 1.5, `RtFireflyMix` 0.9, `RtSpatialStrength`, `RtDepthSensitivity`, `RtNormalSensitivity`, `RtLumaSensitivity` (1 each), `RtTemporalHistory` 0.92, `RtTraceScale` 1 [0.25..1] (lower = faster, noisier).
- Guidance: pick a **setup** that matches the scene (InteriorArchviz, ExteriorArchviz, WetSurfaces...) before editing single numbers. Noise: more denoise passes / temporal history, or raise `RtTraceScale`. Speed: lower `RtTraceScale`, `RtBounces` 1, or the `Performance` setup.

## Image quality / speed (engine page)
- `GraphicsPreset` Ultra | High | Mid | Low | Custom: a full quality bundle (resolution is never changed by presets). Changing individual values makes it Custom.
- `RenderScale` [0.25..2] internal 3D scale (engine page: ignored/forced to 1 when `AiScaling` is None) and render-page `Upscaler` TSR3 | FSR3 | None with `RenderScale`. Engine `AiScaling` None | FSR3 | TSR (TSR = built-in temporal super-resolution).
- Anti-aliasing: `SceneAntiAliasing` Off|X2|X4|X8 (hardware MSAA on the 3D path, same as render-page `SceneMsaa`), `GuiAntiAliasing` (same as `GameGuiMsaa`); render page also has `OverlayMsaa`, `EditorGuiMsaa`.
- `TextureQuality` Ultra|High|Mid|Low (downscales imported 3D textures by 1/2/4/8: affects imports, not already loaded textures); `ShaderQuality` (stored, not yet wired at runtime); `ShadowQuality` (shadows.md); `BloomQuality`, `LensFlareQuality` (postprocess.md); `VolumetricLighting` (volumetrics.md).
- Render page Performance: `HalfResShading`, `HalfResResolve`, `ResolveTileSkip` (on), `GpuDrivenInstances` (on).
- Culling: `InstanceCullMode` CpuNoCull | InstanceCull | GpuBvhCull (default GpuBvhCull), `EnableGpuBvhCull`, `EnableOcclusionCulling` (off; if meshes pop in/out when the camera moves, keep it off).
- Flux LOD (page `flux_lod`): `Enable` (on) and `Quality` HighPerformance | Performance | Quality | HighQuality (coarser steps recook meshes).
- Threading (engine page): `MultiThreadedGraphUpdate`, `MultiThreadedRender`. `PresentUncapped`.
- Display HDR (page `global`): `Enable`, `OutputMode` Auto|Scrgb|Hdr10, `PaperWhiteNits`, `MaxNits`, `UiBrightness`. Changing these recreates the swapchain and affects the whole editor window: only change on request.

## Typical requests
- "Make it look better": postprocess.md + ray tracing setup + lighting first; then GTAO, bloom.
- "Make it faster": engine `GraphicsPreset` Mid/Low, `RenderScale` 0.7-0.85 with an upscaler, lower `ShadowQuality`, fewer shadowed/volumetric lights, `RtTraceScale` down, check the shadow budget.
- Report which values you changed (old -> new): settings are not undoable.
