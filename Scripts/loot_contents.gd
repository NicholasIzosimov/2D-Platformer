class_name LootContents
extends RefCounted

signal changed
var stacks: Array[ItemStack] = []

static func roll(table: LootTable, rules: GearRules, level: int, min_rarity: Rarity = null) -> LootContents:
	var contents := LootContents.new()
	var gold: int = table.roll_gold(level)
	if gold > 0 and table.currency:
		contents.stacks.append(ItemStack.new(table.currency, gold))
	var item: GearData = table.roll_item(rules, level, min_rarity)
	if item:
		contents.stacks.append(ItemStack.new(item))
	return contents

func take(index: int) -> bool:
	var stack: ItemStack = stacks[index]
	if stack == null:
		return false
	var left: int = 0
	if stack.item is CurrencyData:
		PlayerState.add_gold(stack.amount)
	else:
		left = PlayerState.add_to_bag(stack.item, stack.amount)
	if left == stack.amount:
		return false
	if left > 0:
		stack.amount = left
	else:
		stacks[index] = null
	changed.emit()
	return left == 0

func is_empty() -> bool:
	return stacks.all(func(stack): return stack == null)

static func roll_stock(table: LootTable, rules: GearRules, level: int, count: int, min_rarity: Rarity = null) -> LootContents:
	var contents := LootContents.new()
	for i in count:
		var item: GearData = table.generate_item(rules, level, min_rarity)
		if item:
			contents.stacks.append(ItemStack.new(item))
	return contents
