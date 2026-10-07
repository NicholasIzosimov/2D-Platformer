# Working title: 2D Classic WoW — guide for Claude

Godot 4.7 / GDScript. Solo project. Read this first, then `docs/todo.md` for the current todo list and open decisions.

## How to work with the user (most important)

- **Advisory role only.** Do not edit game scripts, scenes or resources. The user writes all code. Give precise instructions with exact, copy-pasteable GDScript; the user places it. Allowed without asking: git commit/push when the user asks, and these docs.
- **Always name the file** (`combat_handler.gd`, `hud.tscn` …) for every change or explanation — many scripts look alike.
- **Placement wording:** prefer giving **whole replacement functions** over "insert after line X". If inserting, quote the exact anchor line and say inside/outside the block. Never count tabs. The user finds vague placement wording confusing.
- **Scene steps:** explicit menu paths, node types and relationships — always "child of X" / "sibling of X", never "under that". Mention "Access as Unique Name" when code uses `%Node`.
- **Check the actual code before answering** "did we…/does X…" and before giving changes. The user often has not applied earlier suggestions, or applied them differently — base instructions on the current file state.
- **No hidden assumptions:** surface undecided design choices (formulas, caps, ordering, which unit counts) as explicit questions or clearly labeled placeholders. Balance numbers are placeholders, not debates.
- **No band-aid fixes:** fix the structure, think ahead, design for change. The user explicitly dislikes "path of least resistance".
- **Units are identical by default:** shared defaults on data resources; the player differs only via PlayerState (class, talents, gear), enemies via spawn data / their UnitData. No per-class special cases in scripts.
- Keep steps small and explanations tight; no long line-by-line commentary.
- The user is a self-described beginner in Godot but reads GDScript fine and understands the architecture.

## Git

- Working branch: `topdown-prototype` (main still holds the old side-view version). Remote: `https://github.com/NicholasIzosimov/2D-Platformer.` — the repo name **ends with a period**.
- Claude may commit and push when asked. Never commit Godot `*.tmp` files (`git add -A -- . ':!*.tmp'`). `gh` CLI is not installed (PRs are opened via the GitHub compare page).

## The game

Top-down action RPG roguelite with **WoW Classic tab-target combat**: GCD, cast times, auto-attack swing timer, aggro/leash/social pulls, few deliberate enemies, dangerous fights. Pitch: "WoW Classic Hardcore as a roguelite". Combat feel comes first. Runs: levels, one big skill tree (classless builds — no classes), (soon) gear and loot, bosses as acts; infinite chunk-generated world.

## Architecture map

**Scenes**
- `Unit.tscn` — base for every unit: UnitStats, CombatHandler, UnitAnimator, AutoAttack, CombatState, Hurtbox, AttackPivot/AttackHitbox, Bars (nameplate: HealthBar w/ LevelLabel, CombatIcon, DebuffContainer), CombatText, EffectVisuals, TargetIndicator. `Player.tscn` and `Enemy.tscn` inherit it.
- `main_menu.tscn` (main scene) → `combat_scene.tscn` — world (Ground/Obstacles TileMapLayers, WorldGenerator, FlowField, SpawnDirector, EnemySpawner, NameplateStacker, PlayerCombatController, CanvasModulate) + CanvasLayer (HUD, CharacterPane, TalentPane, ErrorText).
- `hud.tscn` (independent anchored elements: player/target UnitFrames, CastBar, SwingBar, EnduranceBar, AbilitySlots, XPBar, CombatIndicator), `unit_frame.tscn`, `talent_pane.tscn`, `projectile.tscn`, `campfire.tscn`, `ability_slot.tscn`, `character_pane.tscn`.

**Core scripts**
- `unit_stats.gd` — stats as data: `values[Stat.Type]`, `get_stat` / `modify_stat` (side effects for VIGOR→health, MAX_POWER), health/power, level + LevelScaling (`set_level` applies the difference), rating→% (`hit_percent`, `crit_percent`).
- `ResourceScripts/stat.gd` — `Stat.Type` enum (**append-only**, saved as indices), labels, % formatting.
- `combat_handler.gd` — cast_ability / swing (auto-attack) / deliver (windups) / release (projectile, spawn, self-buffs) / resolve_effects + hit_target (AoE splash), reach (range, min_range, hitbox), line of sight, status effects (`apply_effect`), miss/crit vs target level, `scaled_damage`, `visual_key`/`play_effect`.
- `player_combat_controller.gd` — targeting (hover, selected, Tab, auto-select), `try_cast_slot`, slot tints/sweeps, `target_changed` signal. `enemy_combat_controller.gd` — aggro/leash/social pulls, flow-field chase, retreat inside min range, ability priority list, corpse/death.
- `unit_animator.gd` — name-based animations; `auto_attack.gd` swing timer; `combat_state.gd` in/out of combat + OOC regen; `rewards.gd` XP on death.
- `States/player_state.gd` (autoload **PlayerState**) — `player_data` (= `Resources/Units/player.tres`: starting abilities, power), `start_run()`, player's **runtime ability copies** (`get_ability`, `learn_ability`; talents never touch shared .tres), learned/equipped abilities, talents (ranks, `points_spent`, unlock rule: a required node maxed + `points_required`, `apply_talent_rank`), `bonus_stats`, XP/level. `player_state_loader.gd` applies it to the player unit.
- UI: `main_menu.gd` (Start Run → `PlayerState.start_run()`), `layout_editor.gd` (Unlock UI: drag any HUD child, 8 px grid, saved as offsets-from-default in user://ui_layout.cfg), `hud.gd` (one action slot per `cast_N` input action, fixed keybinds, Shift+drag swaps), `ability_slot.gd` (reads cooldown/GCD from CombatHandler), `unit_frame.gd` (auto-cropped portraits, badges), `smooth_bar.gd` (+ health/power/endurance/xp bars with `bind()`), `swing_bar.gd`, `talent_pane.gd` + `tree_viewport.gd` (pan/zoom, centres on start node) + `skill_tree.tscn` (`skill_tree_view.gd` draws links; hand-placed `talent_node.gd` buttons — a TalentNode nested under another requires it, `parents` = extra links for joins), `describe.gd` (auto descriptions), `rich_tooltip.gd`, `time_format.gd`, `nameplate_stacker.gd`, `character_pane.gd`.
- Scale: `yards.gd` (`Yards.to_px`, 25 px per yard — every gameplay distance/speed is in yards), `camera_follow.gd` (integer pixel-perfect zoom from window size, scroll-wheel zoom steps with spring zoom), `screen_sized.gd` (world UI — nameplates, cast bars, combat text, XP text — counter-scaled to keep screen size; pivot = anchored point).
- Light & shadows (faked, no real 2D shadows): `light_source.gd` (LightSource = PointLight2D with `ground_height`, `brightness()`, `light_info(at)`; joins group itself), `moon_light.gd` (MoonLight = DirectionalLight2D, constant shadow direction, `illumination`), `lighting.gd` (`lights_at` asks every group member's `light_info`: strength/direction/distance; `light_at` total — meant for perception too), `shadow_caster.gd` (one shadow per nearby light, slots stick to their light, darkness × share of total light), `unit_shadow.gd` + `unit_shadow.gdshader` (silhouette copy of the unit sprite, mirrored at the feet, rotated away from its light, tapered; dissolve swap between standard/lit shadows).
- World: `world_generator.gd` (chunks + TerrainShape), `flow_field.gd`, `spawn_director.gd`, `enemy_spawner.gd`, `camera_follow.gd`.

**Data resources (`Scripts/ResourceScripts`, instances in `Resources/`)**: AbilityData (inspector groups; damage/power_gain + StatusEffect list, category, requires_target, spawn_scene, AoE, projectile, windup, animation_key, description), StatusEffect (ticks, heal %, stat modifier, aura/glow, frame badge), UnitData (base_stats dict, level_scaling, auto_attack, swing time, OOC regen, abilities, portrait), TalentData (stat bonuses, ability mods, granted ability, points_required)/AbilityMod, PowerData (colour, in/out-of-combat rate, starting %, power on kill), LevelScaling, XpCurve, SpawnLevelRule, SpawnTable/SpawnEntry, LevelColors.

**Naming conventions**
- Unit animations: `<key>_<action>` in `Resources/Animations/unit_animation.tres`; key = UnitData file name (player: `player_idle`); variants `_2`, `_3` (random); `<key>_combat_<action>` used in combat; optional `_dash`, `_sheathe`, `_unsheathe`.
- Art scale: 16 px gameplay grid (tiles), ~32 px characters on 64×64 frames, every sprite at scale 1 (Tiny Swords leftovers temporarily scaled), unit origin at the feet (Y-sort); props: ground contact point at origin.
- Effects in `effect_animations.tres`: `<ability file>_projectile/_impact/_aoe`, `<status effect file>_aura`.
