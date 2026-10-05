# Todo list, status and open decisions

Last updated 2026-10-02 (branch `topdown-prototype`, latest commit c50b2ab + uncommitted nameplate stacking).

## Already done from the list
- 6 Unit frames with portraits (player + target, badges for combat / campfire)
- 7 Hit → Hit Chance (plus Hit/Crit Rating that scale with level)
- 15 Ranged enemies back away inside their min range
- 30 Nameplate stacking (closest enemy's plate at the bottom)
- 25 Enemy OOC regen exists for all units (1%/s) — for 3% set `out_of_combat_regen` on enemy UnitData
- 16 Spell selection via talents: mechanism exists (talents grant abilities); spells still to design

## Recommended order (Claude's take)

**1. Quick wins (one session)**
- Extras: decimals below 1 on bars, projectile 1 s wall-grace, talent point reminder

**2. Damage model (14) — before gear**
Agreed direction: flat damage / "attack power" stat (weapons say "+5 Damage") × per-ability coefficient (from cast time, ticks, duration, swing time) → % multipliers (primary stat, Damage %) → crit → variance last (already in `UnitStats.take_damage`).
Also open: baseline scaling is broken (health ×50 vs damage ×2 by level 50 with current LevelScaling) — decide target time-to-kill for same-level fights, then set per-level values. Armor uses a fixed constant (400); consider scaling it with attacker level (WoW-style).

**3. Loot pillar: 1, 13, 12, 8 (drops)**
Items as data on the Stat system → drops lying in the world showing their icon (pick up with E / click) → bags on B → equipping into the character pane gear slots → gold; drop/XP scaling by enemy level.

**4. Perception system: 2, 4, 32, 8 (aggro range)**
One formula per enemy: base range × level difference × light (larger without campfire) × crouch, plus line-of-sight / cover rules (hiding in bushes breaks aggro). Unique selling point — build as one system.

**5. World & atmosphere: 3, 22, 23, 21, 20**
Forest assets, enemy camps with assigned enemy groups, enemies near objects (tents), gradual per-level world shift, then map/minimap. Decide in 20 whether terrain is kept or discarded during progression.

**6. Progression content: 29, 17, 18, 31**
More talents/abilities (e.g. Thunder-Clap-style AoE that spreads Gushing Wound), shop, boss arena (big top HP bar, dodge-heavy AoE), quests.

**UI (mix in anytime):** 10 stat descriptions, 26 juicy numbers, 27 buff/debuff box, 24 + 28 keybinds and UI options, incl. per-slot/per-spell target priority (hover vs selected; default = selected wins), fonts/style, DPS meter.

## Full original list
1 Gear drop, gold drop · 2 LoS/bush hiding drops aggro · 3 Trees/bushes, forest start area · 4 Bigger aggro radius without campfire light · 5 Damage variance ✔ · 6 Unit frames ✔ · 7 Hit chance ✔ · 8 Scale drops/XP/aggro range by enemy level vs player level · 9 Tab target ✔ (aggro range + on screen + LoS) · 10 Char stat descriptions · 11 Selected target priority ✔ (per-spell option later) · 12 Bags on B · 13 ARPG ground loot (icon, E / click to pick up) · 14 Attack-power style flat damage + coefficients · 15 Ranged move away ✔ · 16 Spell selection via talents · 17 Shop · 18 Boss arena + shop spawn · 19 Power colour per resource ✔ · 20 Minimap/map, terrain persistence · 21 Gradual asset mix shift per level · 22 Enemy camps/clusters · 23 Enemies near objects (camps, tents) · 24 Keybinding system · 25 Enemy regen 3% ✔(data) · 26 Juicy numbers · 27 WoW-like buff/debuff display · 28 UI hover options · 29 AoE that spreads Gushing Wound · 30 Plate staggering ✔ · 31 Quests · 32 Crouch (slower, smaller aggro range)

Extras: DPS meter · boss mechanics · terrain-destroying enemies (goblins) · slightly more spawns per level · scroll-wheel zoom (decide max) · Warmth fades out softly · right-click auto-walk to target · fonts/UI style · talent point reminder · idle enemies avoid each other · projectile wall grace period · decimals below 1 on bars

## Open design decisions (ask, don't assume)
- **Spellbook:** (1) full WoW bars, (2) Guild Wars 1 style: spellbook + limited bar (~8 + utility row) swappable only out of combat — Claude's recommendation, (3) original fixed slots with discard. PlayerState already keeps learned vs equipped.
- **DoT talent builds** (Gushing Wound: faster ticks, haste scaling, crits, longer/stronger): needs talent mods for StatusEffect fields, player ability copies that also copy their effects (currently shallow `duplicate()` shares effects!), per-effect `can_crit` instead of only `UnitStats.dots_can_crit`.
- Auto-attack crits: currently big yellow like all crits; maybe big white.
- Physics interpolation is ON: anything teleported (player start, enemy spawn placement, projectiles, spawned objects) may need `reset_physics_interpolation()`.
- Big telegraphed enemy attacks: long windups stretch the attack animation (slow-mo look); proper fix is a looping `<key>_windup` pose.
- Cleanup backlog (group A): cache `get_node` with @onready, remove dead code, single dead flag, constants for layers/groups, `cast_cancel` reason.
