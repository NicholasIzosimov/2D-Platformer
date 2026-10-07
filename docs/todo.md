# Todo list, status and open decisions

Last updated 2026-10-07 (branch `topdown-prototype`, latest commit ee46ae0). Numbers = the user's list below. Remove items when done.

## Recommended order (work through one at a time)

**0. Classless restructure — steps 1–3 done (classes removed, skill tree scene, pan/zoom pane); step 4 left**
No classes: one player (`player.tres` holds starting abilities, power, animation key `player_*`), one big skill tree. Steps: (1) remove ClassData + class select → Start Run; (2) skill tree as a scene: hand-placed `TalentNode`s with links, @tool line drawing; unlock rule stays "linked parent maxed" + new "points spent in tree ≥ X" requirement per node; (3) tree pane with pan/zoom, grows from centre; (4) per-ability animations (`player_<ability>` → fallback `player_attack`). One power resource for now; keep `UnitStats.set_power_data` so a keystone/transformation can swap it later (e.g. skeleton form → Dread). Primary stat displayed as "Power"; AP shown, primary hidden in the character pane.

**NEXT SESSION (top priority): preliminary scaling that is thought out**
Problem seen 2026-10-07: a level 3 Warrior already hits far too hard — enemies get AP like the player (1 primary = 1 AP) and base damages are tiny (1–2), so AP dominates early; primary grows with exponent 1.4 vs vigor 1.2 so damage outpaces health. Plan: pick a target time-to-kill for same-level fights (e.g. enemy needs ~N swings to kill you, you need ~M hits), match the primary and vigor curves in `level_scaling.tres` (same exponent), raise base damages so AP is a bonus, not the whole hit. Also consider armor vs attacker level and the level-difference miss/crit. Quick relief meanwhile: lower `primary_stat_per_level`.

**1. Damage model — 9 (before gear)** — AP system DONE (formula, coefficients, `ap_scaling`); remaining: the scaling above

**2. Loot pillar — G, 8, 7, 5 (drops/XP part)**
Items as data on the Stat system → gear + gold drops lying in the world showing their icon (pick up in range by click or E prompt) → bags on B → equip into character pane gear slots → drop/XP scaling by enemy level.

**3. Perception system — 1, 2, 5 (aggro part)**
One aggro-range formula per enemy: base × level difference × light (larger without campfire), plus line-of-sight / cover rules (hiding in a bush while out of LoS drops aggro). Unique selling point — build as one system.

**4. World & atmosphere — 4, 3, 15, 16, 14, 13**
Own forest art (trees/bushes, 16 px tiles + ~40 px characters at camera zoom ×2 if switching art scale), lighting that interacts with obstacles (shader / LightOccluder2D — ties into 2), enemy camps with assigned groups, enemies near objects (tents), gradual per-level asset shift, then map/minimap. Decide in 13 whether terrain is kept or discarded during progression.

**5. Progression content — 10, 22, 11, 12, 23**
Spell selection via talents (mechanism exists: talents grant abilities), Thunder-Clap-style AoE that spreads Gushing Wound, shop, boss arena (big top HP bar, dodge-heavy AoE) + shop spawn, quests.

**UI / small (mix in anytime) — 6, 19, 20, 17, 21, 18**
Char stat descriptions, juicy numbers, WoW-like buff/debuff box (movable via layout editor), keybinding system, UI options incl. hover behaviour and per-slot/per-spell target priority (default = selected wins). 18 enemy OOC health regen already exists (1%/s default) — just set `out_of_combat_regen` = 3 on enemy UnitData. Also: options menu on Escape (move "Unlock UI" there), fonts/style, DPS meter.

## The user's list
G Gear drop, gold drop · 1 LoS/bush hiding drops aggro · 2 Bigger aggro radius without campfire light · 3 Lighting that reflects on obstacles (shader?) · 4 Own trees/bushes, forest start area · 5 Scale drops/XP/aggro range by enemy level vs player level · 6 Char stat descriptions · 7 Bags on B · 8 ARPG ground loot (icon, click in range / E prompt) · 9 AP-style flat damage + coefficients · 10 Spell selection via talents · 11 Shop · 12 Boss arena + shop spawn · 13 Minimap/map, terrain persistence · 14 Gradual asset mix shift per level · 15 Enemy camps/clusters · 16 Enemies near objects (camps, tents) · 17 Keybinding system · 18 Enemy OOC health regen 3%/s · 19 Juicy numbers · 20 WoW-like buff/debuff display · 21 UI hover options · 22 AoE that spreads Gushing Wound · 23 Quests

Extras: DPS meter · boss mechanics · terrain-destroying enemies (goblins) · slightly more spawns per level · scroll-wheel zoom (decide max) · Warmth fades out softly · right-click auto-walk to target · fonts/UI style · talent point reminder · idle enemies avoid each other · projectile wall grace period · decimals below 1 on bars · crouch (slower, smaller aggro range — dropped from main list)

## Open design decisions (ask, don't assume)
- **Lighting:** campfire light is done (Add blending, current saturation is intended). Possible later idea: limit light sources within X range (e.g. max N campfires per area) if many fires stacked ever look blown out.
- **Spellbook:** (1) full WoW bars, (2) Guild Wars 1 style: spellbook + limited bar swappable only out of combat — Claude's recommendation, (3) original fixed slots with discard. PlayerState keeps learned vs equipped; bar shows one slot per `cast_N` action but PlayerState allows 20 equipped → talent-granted abilities can land in hidden slots.
- **Art scale:** current tiles are 64 px drawn at 0.5 scale. Own art plan: 16 px tiles + ~36–45 px characters (64×64 frames), camera zoom ×2, all sprites scale 1; halve pixel-based tunables (or move them to yards first).
- **Power Regen stat** applies in combat only (placeholder); `bot_power.tres` has no out-of-combat rate (enemies don't regen power OOC — left as is for now).
- **DoT talent builds** (Gushing Wound: faster ticks, haste scaling, crits, longer/stronger): needs talent mods for StatusEffect fields, player ability copies that also copy their effects (currently shallow `duplicate()` shares effects!), per-effect `can_crit` instead of only `UnitStats.dots_can_crit`.
- Auto-attack crits: currently big yellow like all crits; maybe big white.
- Physics interpolation is ON: anything teleported (player start, enemy spawn placement, projectiles, spawned objects) may need `reset_physics_interpolation()`.
- Big telegraphed enemy attacks: long windups stretch the attack animation (slow-mo look); proper fix is a looping `<key>_windup` pose.
- Cleanup backlog (group A): cache `get_node` with @onready, remove dead code, single dead flag, constants for layers/groups, `cast_cancel` reason.
