# Todo list, status and open decisions

Last updated 2026-10-07 (branch `topdown-prototype`). Numbers = the user's list below. Remove items when done.

## Recommended order (work through one at a time)

**NEXT SESSION (top priority): preliminary scaling that is thought out**
Problem seen 2026-10-07: a level 3 Warrior already hits far too hard — enemies get AP like the player (1 primary = 1 AP) and base damages are tiny (1–2), so AP dominates early; damage outpaces health. Current state of the code (checked 2026-10-07): `level_scaling.tres` has vigor 2/level ^1.4, primary 1/level ^1.2, armor 5/level ^1.4; `combat_handler.gd` `scaled_damage` uses PRIMARY twice on purpose — as a % multiplier on base damage (`PRIMARY_STAT_SCALING` 0.01) and as AP via `UnitStats.ability_power()` × coefficient — two scaling paths, one early-heavy, one late. Plan: pick a target time-to-kill for same-level fights (e.g. enemy needs ~N swings to kill you, you need ~M hits), match the primary and vigor curves in `level_scaling.tres` (same exponent), raise base damages so AP is a bonus, not the whole hit. Also consider armor vs attacker level and the level-difference miss/crit. AP system itself is done (formula, coefficients, `ap_scaling`).

**1. Loot pillar — 1, 11, 10, 8 (drops/XP part)**
Done: ItemData (stats, weapon attack_speed, item_level, rarity), starting gear, equip/unequip, bag pane in HUD (B, no pause, gold row), WEAPON_DAMAGE, HASTE_RATING. Item generation: ItemTemplate (set = forced, empty = rolled: rarity, extra stats; forced_stats weight = budget share) → ItemRules.generate (budget = level curve × rarity × slot, stat costs, stat pool, constant armor on armor_slots, weapon damage from speed). LootTable (one item_chance roll, then template by weight; gold by level) — global on Enemy.tscn Rewards + optional UnitData.loot_table; drops currently go straight to bag/purse. NEXT: ground loot — gold walk-over magnet, items click-in-range or E nearest (spawned by Rewards.grant_loot instead of add_to_bag). Then: drop chance vs player/mob level difference, bag-full handling. Later: rarity-tinted slot backgrounds, drag & drop. Then lying in the world showing their icon (pick up in range by click or E prompt) → bags on B → equip into character pane gear slots → drop/XP scaling by enemy level.
Visible gear plan: (1) anchor points per body-animation frame (hidden marker-pixel layer in the art: head/hand → offsets) so helmets/weapons/offhands are single drawings snapped to anchors in every animation; (2) abilities share a small set of base motions (slash, thrust, overhead, cast, channel, throw) via `animation_key`, uniqueness from effects; (3) later, layered synced sheets only for deforming pieces (chest/legs) and only for base motions; palette-swap shader for tiers. Shadows must then project the gear layers too.

**2. Light & perception — 3, 4, 8 (aggro part)** — the core mechanic
Perpetual night: living beings are drawn to light, hide in the shadows, a campfire is a risk (enemies drift towards lights slowly; light doesn't pass LoS). One aggro formula per enemy: base × level difference × how lit the player is, plus LoS/cover rules (hiding in a bush out of LoS drops aggro). Building blocks exist: `Lighting.light_at` (total light at a spot; moon must count as background light, not exposure), `light_info` per light, LoS checks. Possibly add LoS per light so walls block light for perception.

**3. World & atmosphere — 7, 2, 17, 18, 16, 15, 5**
Own forest art (trees/bushes; 16 px grid, ~32 px characters), shadows from lights for props/objects (2: reuse the projected silhouette shadow for static props, ground point at origin), enemy camps with assigned groups (17: a SpawnGroup resource — list of units + counts, spawned together in a radius; spawn table entries can point to a unit or a group), enemies near objects (18), gradual per-level asset shift (16), map/minimap + decide terrain persistence (15), random dungeons with set layouts and mini bosses via cave entrances (5).

**4. Progression content — 12, 13, 14, 22**
Spell selection via talents (mechanism exists: talent nodes grant abilities), shop, boss arena (big top HP bar, dodge-heavy AoE) + shop spawn, quests. Classless step 4 still open: per-ability animations (`player_<ability>` → fallback `player_attack`).

**In-game saving**
Save a run to `user://` (ConfigFile/JSON or a custom Resource via ResourceSaver): PlayerState (level, XP, talent ranks, learned/equipped abilities, bonus stats, gold, later gear/bags) + world seed + player position; enemies not saved. Decided: always autosaves, death = run over. Save on events: campfire lit, level up, talent point spent, gear pickup, death (+ on quit). Write to a temp file then rename. Open: multiple slots?

**Quests:** random kill quests + quest log (L) + ActionIcon done. Later: quest giver NPCs (`!`/`?` as more ActionIcon actions), always-on tracker vs log, move CharacterPane/BagPane/ErrorText into HUD for Unlock UI (QuestLog already there; uses fixed position, consider anchors).

**UI / small (mix in anytime) — 9, 20, 19, 21**
Char stat descriptions, juicy numbers, keybinding system, UI options incl. hover behaviour and per-slot/per-spell target priority (default = selected wins). Also: options menu on Escape (move "Unlock UI" there), fonts/style, DPS meter. Buff/debuff boxes are done (movable, preview in Unlock UI, slide/fade animations).

## The user's list (2026-10-07)
1 Gear drop, gold drop · 2 Shadows from light sources for objects · 3 LoS/bush hiding drops aggro · 4 Light as mechanic: perpetual night, beings drawn to light, hide in shadows, campfires risky · 5 Random dungeons (layouts, mini bosses, cave entrances) · 6 Shadow fades out when its light dies ✔ (brightness-weighted light strength) · 7 Own trees/bushes, forest start area · 8 Scale drops/XP/aggro range by enemy level vs player level · 9 Char stat descriptions · 10 Bags on B · 11 ARPG ground loot · 12 Spell selection via talents · 13 Shop · 14 Boss arena + shop spawn · 15 Minimap/map, terrain persistence · 16 Gradual asset mix shift per level · 17 Enemy camps/clusters · 18 Enemies near objects (camps, tents) · 19 Keybinding system · 20 Juicy numbers · 21 UI hover options · 22 Quests

Extras: DPS meter · boss mechanics · terrain-destroying enemies (goblins) · slightly more spawns per level · right-click auto-walk to target · fonts/UI style · talent point reminder · idle enemies avoid each other · projectile 1 s wall-collision grace · decimals below 1 on bars

## Open design decisions (ask, don't assume)
- **Lighting:** campfire light done (Add, current saturation intended). Moon = `MoonLight` (DirectionalLight2D + `moon_light.gd`, constant shadow direction, `illumination` competes with fires). Shadow darkness = lit_alpha × (light / (ambient + all lights))^share_contrast. Possible later: limit light sources per area; per-pixel shadow washout where a shadow reaches into another light.
- **Spellbook:** (1) full WoW bars, (2) Guild Wars 1 style: spellbook + limited bar swappable only out of combat — Claude's recommendation, (3) original fixed slots with discard. PlayerState keeps learned vs equipped; bar shows one slot per `cast_N` action but PlayerState allows 20 equipped → talent-granted abilities can land in hidden slots.
- **Power Regen stat** applies in combat only (placeholder); `bot_power.tres` has no out-of-combat rate (enemies don't regen power OOC — left as is).
- **DoT talent builds** (Gushing Wound: faster ticks, haste scaling, crits, longer/stronger): needs talent mods for StatusEffect fields, player ability copies that also copy their effects (currently shallow `duplicate()` shares effects!), per-effect `can_crit` instead of only `UnitStats.dots_can_crit`.
- Auto-attack crits: currently big yellow like all crits; maybe big white.
- Physics interpolation is ON: anything teleported (player start, enemy spawn placement, projectiles, spawned objects) may need `reset_physics_interpolation()`.
- Big telegraphed enemy attacks: long windups stretch the attack animation (slow-mo look); proper fix is a looping `<key>_windup` pose.
- Cleanup backlog (group A): cache `get_node` with @onready, remove dead code, single dead flag, constants for layers/groups, `cast_cancel` reason.
