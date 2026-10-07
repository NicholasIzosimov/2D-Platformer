extends RefCounted

class_name Stat

enum Type {
	VIGOR,
	PRIMARY,
	ARMOR,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	MISS_CHANCE,
	HIT_CHANCE,
	DAMAGE_PERCENT,
	DAMAGE_REDUCTION,
	MOVE_SPEED,
	HASTE,
	MAX_POWER,
	POWER_GENERATION,
	DODGE,
	PARRY,
	BLOCK,
	HIT_RATING,
	CRIT_RATING,
	ABILITY_POWER,
	WEAPON_DAMAGE,
	}
const LABELS: Dictionary = {
	Type.VIGOR: "Vigor",
	Type.PRIMARY: "Power",
	Type.ARMOR: "Armor",
	Type.CRIT_CHANCE: "Crit Chance",
	Type.CRIT_DAMAGE: "Crit Damage",
	Type.MISS_CHANCE: "Miss Chance",
	Type.HIT_CHANCE: "Hit Chance",
	Type.DAMAGE_PERCENT: "Damage",
	Type.DAMAGE_REDUCTION: "Damage Reduction",
	Type.MOVE_SPEED: "Move Speed",
	Type.HASTE: "Haste",
	Type.MAX_POWER: "Max Power",
	Type.POWER_GENERATION: "Power Regen",
	Type.DODGE: "Dodge",
	Type.PARRY: "Parry",
	Type.BLOCK: "Block",
	Type.HIT_RATING: "Hit Rating",
	Type.CRIT_RATING: "Crit Rating",
	Type.ABILITY_POWER: "Ability Power",
	Type.WEAPON_DAMAGE: "Weapon Damage",
}
const PERCENT_STATS: Array = [Type.CRIT_CHANCE, Type.CRIT_DAMAGE, Type.MISS_CHANCE, Type.HIT_CHANCE, Type.DAMAGE_PERCENT, Type.DAMAGE_REDUCTION, Type.HASTE, Type.DODGE, Type.PARRY, Type.BLOCK]
const DISPLAY_SCALE: Dictionary = {Type.CRIT_DAMAGE: 100.0}

static func label(type: Type) -> String:
	return LABELS.get(type, "?")

static func format(type: Type, amount: float) -> String:
	var text: String = Describe.number(amount * DISPLAY_SCALE.get(type, 1.0))
	return text + ("%" if PERCENT_STATS.has(type) else "")
