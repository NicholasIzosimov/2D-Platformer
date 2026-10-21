extends RefCounted

class_name Describe

const PROPERTY_LABELS: Dictionary = {
	"range": "Range",
	"min_range": "Minimum Range",
	"cooldown": "Cooldown (sec)",
	"cast_time": "Cast Time (sec)",
	"power_cost": "Cost",
	"damage": "Damage",
	"windup": "Windup (sec)",
	"aoe_radius": "Area Radius",
	"aoe_max_targets": "Targets Hit",
	"aoe_damage_multiplier": "Splash Damage",
}

static func number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.1f" % value

static func signed(value: float) -> String:
	return ("+" if value >= 0.0 else "") + number(value)

static func ability(data: AbilityData, handler: Node = null) -> String:
	var lines: Array[String] = []
	if data.uses_weapon_damage:
		var extra: float = handler.scaled_damage(data.damage, handler.ability_coefficient(data)) if handler else data.damage
		if handler:
			var weapon: float = handler.scaled_damage(handler.own_stats.get_stat(Stat.Type.WEAPON_DAMAGE), 0.0)
			lines.append("Deals Weapon Damage (%s) + %s damage." % [number(weapon), number(extra)])
		else:
			lines.append("Deals Weapon Damage + %s damage." % number(extra))
	elif data.damage > 0.0:
		var damage: float = handler.ability_damage(data) if handler else data.damage
		lines.append("Deals %s damage." % number(damage))
	if data.aoe_radius > 0.0 and data.aoe_max_targets != 1:
		var who: String = "all nearby enemies" if data.aoe_max_targets <= 0 else "up to %d nearby enemies" % (data.aoe_max_targets - 1)
		lines.append("Also hits %s for %d%% of the damage." % [who, roundi(data.aoe_damage_multiplier * 100.0)])
	if data.power_gain > 0.0:
		lines.append("Generates %s power." % number(data.power_gain))
	for effect in data.effects:
		var text: String = status_effect(effect, handler)
		if text != "":
			lines.append(text)
	return "\n".join(lines)

static func status_effect(effect: StatusEffect, handler: Node = null) -> String:
	var parts: Array[String] = []
	var every: String = number(effect.tick_interval)
	if effect.damage > 0.0 and effect.tick_interval > 0.0:
		var damage: float = handler.scaled_damage(effect.damage, handler.effect_coefficient(effect)) if handler else effect.damage
		parts.append("deals %s damage every %s sec" % [number(damage), every])
	if effect.heal_percent > 0.0 and effect.tick_interval > 0.0:
		parts.append("heals %s%% of max health every %s sec" % [number(effect.heal_percent), every])
	if effect.stat_amount != 0.0:
		var verb: String = "increases" if effect.stat_amount > 0.0 else "reduces"
		parts.append("%s %s by %s" % [verb, Stat.label(effect.affect_stat), Stat.format(effect.affect_stat, absf(effect.stat_amount))])
	if parts.is_empty():
		return ""
	var text: String = " and ".join(parts) + " for %s sec." % number(effect.spell_duration)
	return text[0].to_upper() + text.substr(1)

static func talent(data: TalentData, rank: int) -> String:
	var lines: Array[String] = []
	for stat in data.stat_bonuses:
		var per_rank: float = data.stat_bonuses[stat]
		var line: String = "%s%s %s per rank" % ["+" if per_rank >= 0.0 else "-", Stat.format(stat, absf(per_rank)), Stat.label(stat)]
		if rank > 0:
			line += " [color=gray](now %s%s)[/color]" % ["+" if per_rank >= 0.0 else "-", Stat.format(stat, absf(per_rank * rank))]
		lines.append(line)
	for mod in data.ability_mods:
		lines.append("%s: %s %s per rank" % [mod.ability.name, signed(mod.amount_per_rank), PROPERTY_LABELS.get(mod.property, mod.property)])
	if data.grants_ability:
		lines.append("Teaches [b]%s[/b]:" % data.grants_ability.name)
		lines.append(ability(data.grants_ability))
	return "\n".join(lines)

static func stat_line(stat: Stat.Type, amount: float) -> String:
	return "%s%s %s" % ["+" if amount >= 0.0 else "-", Stat.format(stat, absf(amount)), Stat.label(stat)]

static func item(data: ItemData) -> String:
	var color: Color = data.rarity.color if data.rarity else Color.WHITE
	var lines: Array[String] = ["[b][color=#%s]%s[/color][/b]" % [color.to_html(false), data.name]]
	if data is GearData:
		lines.append("[color=gray]Item Level %d[/color]" % data.item_level)
		lines.append("[color=gray]%s[/color]" % GearData.Slot.keys()[data.slot].capitalize())
		if data.attack_speed > 0.0:
			lines.append("Speed %.2f" % data.attack_speed)
		for stat in Stat.sorted(data.stats.keys()):
			lines.append(stat_line(stat, data.stats[stat]))
	if data.gold_value() > 0:
		lines.append("%d [img=16x24]res://Assets/UI/gold_coin.png[/img]" % data.gold_value())
	return "\n".join(lines)

static func item_comparison(candidate: GearData, equipped: GearData) -> String:
	var lines: Array[String] = ["[b]If equipped:[/b]"]
	if equipped and candidate.attack_speed != equipped.attack_speed and candidate.attack_speed > 0.0:
		lines.append("Speed %.2f → %.2f" % [equipped.attack_speed, candidate.attack_speed])
	var current: Dictionary = equipped.stats if equipped else {}
	var stats: Array = candidate.stats.keys()
	for stat in current:
		if not stats.has(stat):
			stats.append(stat)
	for stat in Stat.sorted(stats):
		var diff: float = candidate.stats.get(stat, 0.0) - current.get(stat, 0.0)
		if is_zero_approx(diff):
			continue
		var color: String = "#5fd35f" if diff > 0.0 else "#e05555"
		lines.append("[color=%s]%s[/color]" % [color, stat_line(stat, diff)])
	if lines.size() == 1:
		lines.append("[color=gray]No stat changes[/color]")
	return "\n".join(lines)
