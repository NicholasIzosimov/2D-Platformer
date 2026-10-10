# Shadow test scene (option C) — plan and context

Status 2026-10-10: decided to build a throwaway test scene before deciding whether option C replaces the current shadow system. Nothing built yet. Shop is finished (commit fb678fb).

## Why

The current system (see CLAUDE.md → "Light & shadows") fakes shadows as projected silhouettes drawn in `ShadowLayers` UNDER all props: shadows only land on the ground, each caster shows only its 2–3 strongest lights, and the cost grows with casters × lights on the CPU (`shadow_caster.gd` asks every light every frame; `shade_receiver.gd` checks every shadow for every unit). With "perpetual night, light is the core mechanic, light-heavy boss fights and ability lights", that won't scale and shadows can't fall on tents, units, etc.

Option C = screen-space 2.5D shadows on the GPU: every pixel knows its height above the ground, and per light a shader steps along the ray toward the light; if something taller stands in the way, the pixel is in shadow. Shadows land on everything, every light shadows everything, casters cost almost nothing on the CPU.

## The core trick (keep it this simple in the test)

- **Upright cutout rule:** every sprite is an upright cardboard cutout standing at its origin (the existing prop/unit rule: origin = ground contact point). A pixel's height = how far above its sprite's origin it is. Ground pixels have height 0. No extra art.
- Because of that rule, a pixel's ground position is simply `screen_y + height` (in world pixels), so the height buffer needs only ONE value per pixel (height) plus alpha.
- **Height buffer:** each test sprite gets a copy sprite with a "height encode" shader (outputs height / max_height into a colour channel), drawn on its own visibility layer. A SubViewport sharing the main world (`world_2d`) with `canvas_cull_mask` = only that layer renders the buffer; the main viewport's cull mask excludes that layer. A second Camera2D in the SubViewport copies the main camera each frame.
- **Shadow pass:** a full-screen ColorRect (CanvasLayer above the world) with a shader that reads the height buffer (ViewportTexture). For each screen pixel: start point (x, ground_y, h); step N times toward the light (light x, light ground y, light height); at each step look up the buffer at screen position (x, ground_y − h_ray); if the stored height > ray height + bias AND that occluder's ground y is within a small "thickness" of the ray's ground y → shadowed. Darken accordingly (multiply).
- Ignore self-shadowing in the first version (thin-sprite bias), no soft edges, no merge, no perception.

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
