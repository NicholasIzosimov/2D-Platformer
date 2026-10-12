# Shadow test scene (option C) — plan and context

Status 2026-10-10: decided to build a throwaway test scene before deciding whether option C replaces the current shadow system. Nothing built yet. Shop is finished (commit fb678fb).

## Why

The current system (see CLAUDE.md → "Light & shadows") fakes shadows as projected silhouettes drawn in `ShadowLayers` UNDER all props: shadows only land on the ground, each caster shows only its 2–3 strongest lights, and the cost grows with casters × lights on the CPU (`shadow_caster.gd` asks every light every frame; `shade_receiver.gd` checks every shadow for every unit). With "perpetual night, light is the core mechanic, light-heavy boss fights and ability lights", that won't scale and shadows can't fall on tents, units, etc.

Option C = screen-space 2.5D shadows on the GPU: every pixel knows its height above the ground, and per light a shader steps along the ray toward the light; if something taller stands in the way, the pixel is in shadow. Shadows land on everything, every light shadows everything, casters cost almost nothing on the CPU.

## Alternatives considered (2026-10-10)

The user's pain is CPU cost AND the look: applying shadows is a lot of work per object, frames drop with modest activity (profiled before), shadows look scuffed at angles, some things are hard to cast on. Perception will NOT use shadows (it will use collision boxes / "bush" areas), so a GPU-only shadow picture is fine.
- Optimising the current system (light spatial grid, nearby-only ShadeReceiver at ~10 Hz, re-project only on movement): cheaper CPU, but fixes none of the look problems → rejected.
- Godot built-in LightOccluder2D shadow maps: free on the GPU, but heightless infinite wedges, wrong for upright sprites → maybe later for walls only.
- World height map (top-down texture, ray-march on it): off-screen safe and CPU-readable, but column/blob shapes, and its main benefit (perception) isn't needed → rejected.
- → Option C is the candidate; the test scene decides.

## The core trick (keep it this simple in the test)

- **Upright cutout rule:** every sprite is an upright cardboard cutout standing at its origin (the existing prop/unit rule: origin = ground contact point). A pixel's height = how far above its sprite's origin it is. Ground pixels have height 0. No extra art.
- Because of that rule, a pixel's ground position is simply `screen_y + height` (in world pixels), so the height buffer needs only ONE value per pixel (height) plus alpha.
- **Height buffer:** each test sprite gets a copy sprite with a "height encode" shader (outputs height / max_height into a colour channel), drawn on its own visibility layer. A SubViewport sharing the main world (`world_2d`) with `canvas_cull_mask` = only that layer renders the buffer; the main viewport's cull mask excludes that layer. A second Camera2D in the SubViewport copies the main camera each frame.
- **Shadow pass:** a full-screen ColorRect (CanvasLayer above the world) with a shader that reads the height buffer (ViewportTexture). For each screen pixel: start point (x, ground_y, h); step N times toward the light (light x, light ground y, light height); at each step look up the buffer at screen position (x, ground_y − h_ray); if the stored height > ray height + bias AND that occluder's ground y is within a small "thickness" of the ray's ground y → shadowed. Darken accordingly (multiply). Correction (2026-10-10): for an upright cutout the stored height at that lookup equals the ray height whenever the ground y matches, so "stored height > ray height" is the wrong test — the real test is "opaque buffer pixel there AND its ground y (screen_y + stored height) within thickness of the ray's ground y". Work this out properly at step 5.
- **Height reference (2026-10-10):** height must be measured from the OBJECT's root (ground contact), not from each sprite's origin — props have several sprites with their own offsets (tent at −49/−56, pine sway sprite at −9 with offset). The chest's origin is mid-sprite (ground contact ≈ +9) and breaks the rule.
- Ignore self-shadowing in the first version (thin-sprite bias), no soft edges, no merge, no perception.

## Decisions for the test (2026-10-10, Claude's call — user's goal: "closest to an automated physics system, light coherent on all units and props, most natural look, least friction to create")

- Height copies are made AUTOMATICALLY by a script on the object's root (duplicates every sprite under it, assigns the encode material, visibility layer, offset to the root). Never by hand. Later this lives in prop.tscn / Unit.tscn so every object casts and receives without setup.
- Height encoding: 1 px per step, one 8-bit channel (max 255 px). One constant; switch to two channels if taller objects appear.
- Height buffer: one texel per art pixel (SubViewport = screen / zoom, its camera at zoom 1).
- One rule for all objects: origin = ground contact. The chest gets fixed in chest.tscn (sprite and colliders up ~9 px).

## Progress (2026-10-12)

Steps 1–5 built and working: `Scenes/Tests/shadow_test.tscn`, `Scripts/Tests/` (shadow_test_light.gd = ShadowTestLight with `radius()`, height_source.gd on object roots with object id, height_buffer.gd on the SubViewport, shadow_pass.gd on ShadowPass/ShadowRect), `Resources/Shaders/Tests/` (height_encode, shadow_pass). Learned:
- Object id in G channel → objects never shadow themselves.
- Facing rule: cutouts face the camera; a light behind an object darkens its visible side (`back_strength`, `facing_softness`). Fixed "ears on the parasol" (light lighting a cutout's front from behind).
- Patches tried and dropped (light clearance, one-pixel "light inside" lookup, edge-on fade): all were symptoms of ONE root cause — flat cutouts have no depth, so lights near an object's ground line misbehave and side lights cast nothing. User's rule: always cast shadows, never "sometimes none".
- Tried per-object footprints (width × depth): side lights cast, but shapes turned into blobs and it needs a value per object → user rejected ("no manual values, it'll be a headache"). Reverted to the origin-only cutout with ONE global `thickness`.
- Decided: lights can't be inside objects in the game (lights get collision; units can't walk into them). Carried lights will pass their carrier's id to ignore (from code, no manual value). The mouse light can go inside things — ignore those artifacts in the test. Light exactly level with an object's base gives only a thin sideways sliver — accepted.
- Step 6 (2026-10-12): shadows moved INTO the lighting. `shadow_light.gdshaderinc` (global uniforms `shadow_buffer`, `shadow_buffer_rect`, `shadow_params` declared in Project Settings → Shader Globals; ray walk + facing in `shadow_light()`), used by `lit.gdshader` and `sway_lit.gdshader` (`vertex()` sets `shadow_world`/`shadow_scale`, `light()` multiplies LIGHT). Light world position = fragment world + (LIGHT_POSITION − LIGHT_VERTEX) / canvas scale; height = PointLight2D.height (LIGHT_POSITION.z, also / scale) — verified working. `shadow_settings.gd` feeds the globals. `height_source.gd` assigns the lit material to sprites without a material; custom shaders must include the .gdshaderinc themselves (in the game: `sway.gdshader` itself). ShadowPass overlay retired.
- User confirmed: low lights get collision, high lights are safe; edge cases near lights are accepted.
- Step 7 performance (2026-10-13, RTX 2080 Ti, 2560×1440, stress tool `stress_test.gd`: L = +5 lights, P = +10 props, V = pixel mode toggle). Normal mode (lighting computed per screen pixel): 2 lights 122 FPS, 10 lights 32, 30 lights 21, 30 lights + 40 props 11 FPS (GPU ≈ 80 ms; CPU only waits). Early-out for faint light added. Pixel mode (window stretch = viewport, integer scale, world rendered at art resolution 853×480): 30 lights + 40 props → 67 FPS. Resolution is the lever (~6×).
- Godot caps lights per drawn item (~16): ground chunks (TileMapLayer quadrants) with more overlapping lights drop some → hard darker squares. Stress-only; maybe a per-area light budget later.
- Open decision: adopt C with world rendered at art resolution (pixel-perfect; costs smooth spring zoom / sub-pixel camera unless handled)?

## Test scene scope (target 6–10 h of sessions)

1. `Scenes/Tests/shadow_test.tscn`, completely separate from the game (no WorldGenerator, no PlayerState). Root Node2D + Camera2D at a fixed integer zoom like the game.
2. A few real sprites placed by hand: shop tent (`Scenes/Props/Tents/shop_tent.tscn` art), a pine tree, the chest, the player's AnimatedSprite2D (idle) — origins at their feet.
3. One light: a marker that follows the mouse (and a key/slider for its height), plus a PointLight2D for the normal glow so it looks like the game.
4. Height copies via visibility layer + SubViewport + height-encode shader.
5. Shadow pass shader (ray steps, bias, thickness as uniforms to tune live).
6. Then: a second light; an animated/flipped sprite; moving the camera. Judge on the real art: does the cutout rule look right for the tent? Performance with ~20–30 lights?

Decide afterwards: switch (then integrate step by step: units → props → moon → perception check → remove old system), blend (C only on objects), or stay. Graphics options would become tiers within C (steps, buffer resolution, shadowed-light cap, blob fallback) — not two systems.

## Known follow-ups if it is adopted (not part of the test)

Animated frames / flip / sway in height copies (ShadowCaster makes the copy), pixel-perfect + spring zoom, off-screen caster margin, many lights efficiently (batch), the moon (directional light maths), fitting PointLight2D colours / CanvasModulate / additive glows, soft edges, perception (`shade_at`, `light_at`, ShadeReceiver) consistent with the picture, removing ShadowLayers / unit_shadow / merge shader. Optional per-sprite flags: "flat" (rugs, decals) and "depth" for deep objects.

## Estimates given

Test scene 6–10 h; full adoption ~30–55 focused hours (×1.5–2 with our step-by-step workflow). CPU per frame with 50 units + 30 lights: current ~10–20 ms (shadows alone), C ~0.5–1 ms + GPU ~1–3 ms at pixel-art resolution. Rough, unmeasured — verify with the profiler.
