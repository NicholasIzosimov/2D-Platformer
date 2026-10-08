# Todo list, status and open decisions

Last updated 2026-10-08 (branch `topdown-prototype`). Numbers = the user's list of 2026-10-08 (below). No fixed order — these are gentle reminders for when there's no clear direction. Remove items when done.

## The user's list (2026-10-08)

2 (gold value per rarity: `ItemData.gold_value()` from item level × rarity budget multiplier, constants in `item_data.gd`, coin icon in tooltip) and 3 (rarity border, shared by bag + character pane via `gear_slot.gd`) are DONE.
Direction (user): move global rules out of Resources into hard-coded constants where resources have become a mess; per-instance data stays on resources.

**0. Incoming damage numbers combined** — ticks are shown summed every 2 s instead of one number per tick. Open: player only or all units; DoT ticks only or all damage. Lives in `combat_text_spawner.gd`. Related: 17.

**1. Chests (IN PROGRESS, 2026-10-09)** — steps 1–3 done: Interactable component + Interactor on player (hover/nearest highlight + scale tween, E or left click, range, out of combat only), chest sprite states (closed → opening → full gold frame → empty frame; empty = no interaction), LootEntry/LootContents (rolled once on first open: gold + 1 item, `min_rarity` = that rarity or better by `item_rules.tres` order, item level = player level). `chest.gd` still has a TEMPORARY "second click takes everything" loop in `_on_interacted` (replaced by step 4).
Pending code given but maybe not applied: Main Hand assert in `ItemRules.generate`; no gear changes in combat (`PlayerState.in_combat` + `action_failed` signal → ErrorText).
NEXT step 4 — loot window (agreed): LootWindow PanelContainer child of HUD (fixed, Unlock UI movable, like BagPane), title label (reuse for bag pane too), one slot per entry via `gear_slot.tscn` (needs left-click signal + optional amount label: gold slot = coin icon + number, tooltip "N Gold"), left click takes into bag, taken slot stays visible but empty, "Inventory is full" via `action_failed`. Closes on X button, Esc, walking out of range, or when everything is taken. Chest listens to `contents.changed` → empty frame. Leftovers stay; reopen shows the same slots. Generic `open(contents, interactable)` for future loot sources.
Step 5 — world memory: opened chests + leftover contents remembered per structure until world reset (no refills).
Open: weapon budget — weapon damage currently on top of the stat budget and both × slot_budget (Main Hand 2.0); option: weapon damage from level × rarity only.

**Ground loot (intended mechanic)** — drops still go straight to bag/purse (`rewards.gd` → `add_to_bag`). Planned: loot lies in the world showing its icon; gold walk-over magnet, items click-in-range or E nearest. Then bag-full handling (currently the item is silently lost), drag & drop.

**4. Bars artifacty** — scale them cleanly (HUD bars, nameplates).

**5. LoS / bush hiding drops aggro** — hiding out of LoS while in aggro drops all aggro (feels like action). Today: `enemy_combat_controller.gd` only leashes after `leash_time` out of range/LoS. Prop trunks (StaticBody2D, layer 1) already block LoS (`LINE_OF_SIGHT_MASK` = 1); a bush would need to block sight without blocking movement → separate vision layer.

**6. Light interacts with obstacles** — light doesn't pass walls/obstacles (LoS per light), for visuals and perception.

**7. Light as the core mechanic** — perpetual night; living beings are drawn to light; hide in the shadows; a campfire is a risk. Enemies drift slowly towards lights they can see (not through LoS), hover around the inner area at a minimum distance, never walk through fire. One aggro formula per enemy: base × level difference × how lit the player is, plus LoS/cover rules (5). Building blocks: `Lighting.light_at` / `lights_at` / `light_info` (moon must count as background light, not exposure), `ShadeReceiver.shade` (darkest shadow at the feet), LoS checks.

**8. Random dungeons** — set layouts, mini boss at the end, entered through a cave-ish entrance.

**9. Scale drops, XP and aggro range by enemy level** — aggro range relative to player level (higher enemy → larger range, lower → smaller). Today: item level = mob level, XP = `xp_for_enemy_level(enemy level)` (not relative to the player), `aggro_range` is a flat export. Earlier decision: drop chance/gold NOT reduced for low mobs — confirm what "scale drops" means now.

**10. Char stat descriptions** — character pane rows get tooltips (Tooltip autoload: rows implement `tooltip_sections()`).

**11 + 14. Map / minimap + terrain persistence** — M opens a map of the explored seed incl. structures. Decide: is terrain tossed or kept during a run ("Minecraft or random dungeon grinder")? Chunks currently regenerate deterministically from the seed; only `cleared_spawns` is remembered.

**12. Shop.**

**13. Boss arena + shop spawn** — big boss HP bar at the top; dodge-heavy AoE mechanics.

**15. Level gradient of assets** — per level a slightly different asset mix (e.g. stone +5 %/level). Plan: spawn entries get `weight_per_level`; a chunk uses the player level from when it was FIRST generated (store chunk → level, survives unload, cleared on boss world reset). Build once a second prop exists.

**16. Keybinding system.**

**17. Juicy numbers.**

**18. UI options** — incl. which buttons react to hover, per-slot/per-spell target priority (default: selected wins), options menu on Escape (move "Unlock UI" there).

**19. Folder structure** — one folder per thing (ability folder holds its .tres, icon, effects …), better script naming. Caution: animation keys come from FILE NAMES (`<UnitData file>_<action>`, `<ability file>_projectile/_impact/_aoe`, `<status effect file>_aura`) → renaming files breaks animations unless `animation_key` is set; ~17 hard-coded `res://` paths in scripts aren't updated by the editor; move files only in Godot's FileSystem dock.

## Older reminders

- **Scaling pass (was top priority 2026-10-07):** a level 3 Warrior hits far too hard — enemies get AP like the player (1 primary = 1 AP), base damages are tiny (1–2), so AP dominates early; damage outpaces health. `level_scaling.tres`: vigor 2/level ^1.4, primary 1/level ^1.2, armor 5/level ^1.4. `combat_handler.gd` `scaled_damage` uses PRIMARY twice on purpose (% multiplier `PRIMARY_STAT_SCALING` 0.01 + AP via `UnitStats.ability_power()` × coefficient). Plan: pick target time-to-kill for same-level fights, match primary/vigor curves (same exponent), raise base damages so AP is a bonus; consider armor vs attacker level and level-difference miss/crit.
- **Visible gear plan:** (1) anchor points per body-animation frame (hidden marker-pixel layer: head/hand → offsets), helmets/weapons as single drawings snapped to anchors; (2) abilities share a few base motions (slash, thrust, overhead, cast, channel, throw) via `animation_key`; (3) later layered synced sheets only for deforming pieces, palette-swap shader for tiers. Shadows must project gear layers too.
- **Spell selection via talents** (mechanism exists: talent nodes grant abilities). Per-ability animations (`player_<ability>` → fallback `player_attack`).
- **In-game saving:** always autosave, death = run over. Save PlayerState (level, XP, talents, abilities, bonus stats, gold, gear, bag) + world seed + player position; enemies not saved. Save on campfire lit, level up, talent spent, gear pickup, death, quit. Temp file then rename. Open: multiple slots?
- **Quests later:** quest giver NPCs (`!`/`?` ActionIcon actions), tracker vs log, move CharacterPane/BagPane/ErrorText into HUD for Unlock UI.
- **Art/world:** own forest art (bushes, rocks), tent art should face the camera (diagonal sprites break Y-sort), shadow length per light preset (`shadow_length_scale`). Decided: NO canopy fade (hiding behind trees is a mechanic).
- **Extras:** DPS meter · boss mechanics · terrain-destroying enemies (goblins) · slightly more spawns per level · right-click auto-walk to target · fonts/UI style · talent point reminder · idle enemies avoid each other · projectile 1 s wall-collision grace · decimals below 1 on bars.

## Technical backlog

- Props optimisation (only if the profiler shows it): per-chunk activation, cached light list, threaded chunk generation, MultiMesh for flat ground decoration, skip shadow re-projection when unchanged, prop pooling, optional edge vignette.
- Physics interpolation is ON: anything teleported (player start, enemy spawn placement, projectiles, spawned objects) may need `reset_physics_interpolation()`.
- Big telegraphed enemy attacks: long windups stretch the attack animation; proper fix is a looping `<key>_windup` pose.
- Cleanup group A: cache `get_node` with @onready, remove dead code, single dead flag, constants for layers/groups, `cast_cancel` reason.

## Open design decisions (ask, don't assume)

- **Lighting:** campfire light done. Moon = `MoonLight` (constant shadow direction, `illumination` competes with fires). Shadow darkness = lit_alpha × (light / (ambient + all lights))^share_contrast. Possible later: limit light sources per area; per-pixel shadow washout where a shadow reaches into another light.
- **Spellbook:** (1) full WoW bars, (2) Guild Wars 1 style: spellbook + limited bar swappable only out of combat — Claude's recommendation, (3) fixed slots with discard. PlayerState allows 20 equipped but the bar shows one slot per `cast_N` action → talent-granted abilities can land in hidden slots.
- **Power Regen stat** applies in combat only (placeholder); `bot_power.tres` has no out-of-combat rate.
- **DoT talent builds** (Gushing Wound: faster ticks, haste scaling, crits, longer/stronger): needs talent mods for StatusEffect fields, ability copies that also copy their effects (shallow `duplicate()` shares effects!), per-effect `can_crit`.
- Auto-attack crits: currently big yellow like all crits; maybe big white.
