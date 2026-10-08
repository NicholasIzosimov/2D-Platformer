class_name LootContents
extends RefCounted

signal changed
var entries: Array[LootEntry] = []

static func roll(table: LootTable, rules: ItemRules, level: int, min_rarity: Rarity = null) -> LootContents:
	var contents := LootContents.new()
	var gold: int = table.roll_gold(level)
	if gold > 0:
		var gold_entry := LootEntry.new()
		gold_entry.gold = gold
		contents.entries.append(gold_entry)
	var item: ItemData = table.roll_item(rules, level, min_rarity)
	if item:
		var item_entry := LootEntry.new()
		item_entry.item = item
		contents.entries.append(item_entry)
	return contents

func take(index: int) -> bool:
	var entry: LootEntry = entries[index]
	if entry.taken:
		return false
	if entry.item:
		if not PlayerState.add_to_bag(entry.item):
			return false
	else:
		PlayerState.add_gold(entry.gold)
	entry.taken = true
	changed.emit()
	return true

func is_empty() -> bool:
	return entries.all(func(entry): return entry.taken)
