# Shadows

Facts below are the engine's own descriptions (read live with `settings_get`/`node_detail`); recipes are guidance.

## Per light (`GameLight3D`, set with `set_property component:"GameLight3D"`)
- `CastShadows`: master switch. New lights start OFF.
- `ShadowQuality`: High / Mid / Low / Retro. Point/Spot: High = 4K ... Retro = 0.5K shadow maps. Directional: High is about 1 cm clipmap texels (sharpest close to the camera window); Mid/Low/Retro widen the coverage with coarser texels.
- `ShadowResolution`: explicit size (int) if you need to override the tier.
- `Smooth` (soft shadows): soft penumbra via Vogel-disk PCF, rotated per pixel. Off = hard single-tap. Applies to Point/Spot/Directional.
- `SoftShadowsQuality` High / Mid / Low: Vogel filter taps when `Smooth` is on. High = more taps / thinner edge (NOT blurrier). Mid is usually the best balance of solid and soft.
- `SourceRadius`: area light radius in meters for contact-hardening penumbra. 0 = sharp umbra with only the tier's soft edge. 0.02-0.08 gives a soft rim; larger values look blurry.
- `ShadowBias`: extra receiver bias in meters (raises the automatic distance-scaled floor, never replaces it). Directional default 0.005. **Raise it if you see shadow acne.** If shadows detach from objects (peter-panning), lower it.
- `Mobility`: Static caches the unmoving world in the point-light cube map; Moving re-renders the whole cube every frame because the light itself may move. Use Static for lights that never move.
- `StaticMeshComponent.CastShadows` / node `CastShadows`: whether a mesh casts shadows (per-mesh opt-out for tiny/decorative geometry).

## Global shadow settings
| where | setting | meaning |
|---|---|---|
| engine page | `ShadowQuality` Ultra/High/Mid/Low | Authoritative shadow-map size and directional CSM profile: Ultra = 8K atlas with the densest cascades ... Low = 1K / 2 cascades. |
| render page | `ShadowMapCache` | Cache shadow maps for static content. |
| render + engine | `SoftShadowUmbraFloor` | Off (default): fully black umbras unless another light or IBL reaches them. On: deep shadows keep ~12% of the light (older soft-fill look). |
| engine page | `ShadowBudgetEnabled`, `ShadowBudgetMaxLights`, `ShadowBudgetMaxSpotLights` | The shadow budget (below). |
| render page | `RtShadows`, `RtShadowBias` | Ray-traced shadows and their ray bias (see raytracing-and-quality.md). |

## The shadow budget (most common "why has my light no shadow?")
With `ShadowBudgetEnabled` on, **point-light shadows come from a fixed pool of cube maps** (`ShadowBudgetMaxLights`, default **2**; spots use `ShadowBudgetMaxSpotLights`, default **3**). The lights closest to / brightest for the camera get the slots; **every other light casts no shadow even if its `CastShadows` is on.** If a scene has many shadowed point lights: raise the budget numbers (each slot costs VRAM, allocated once), or turn the budget off (`ShadowBudgetEnabled=false` = one cube per shadow-casting light), or reduce how many lights cast shadows.

## Recipes (guidance: verify visually)
- **Crisp sun shadows:** Directional, `CastShadows` on, `ShadowQuality` High, `Smooth` on, `SoftShadowsQuality` Mid, engine `ShadowQuality` High/Ultra.
- **Acne (striped/speckled self-shadowing):** raise `ShadowBias` in small steps (0.005 -> 0.01 -> 0.02).
- **Floating shadows:** lower `ShadowBias`.
- **Too black in shadow:** enable `SoftShadowUmbraFloor`, or add fill (IBL / ambient on the directional light / a weak extra light), do not just raise intensity.
- **Soft contact shadows from a lamp:** point/spot with `SourceRadius` ~0.05 and `Smooth` on.
- **Performance:** `Mobility = Static` for static lights, lower `ShadowQuality` on minor lights (Low/Retro), keep few shadowed lights, lower the engine `ShadowQuality`.
