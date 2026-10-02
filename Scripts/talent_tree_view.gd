extends Control

class_name TalentTreeView

const CELL: float = 72.0
const BUTTON_SIZE: float = 48.0
const PADDING: float = 24.0
const TITLE_HEIGHT: float = 28.0

var tree: TalentTree
var buttons: Dictionary = {}

func setup(new_tree: TalentTree) -> void:
	tree = new_tree

func _ready() -> void:
	var title := Label.new()
	title.text = tree.name
	title.position = Vector2(PADDING, 4)
	add_child(title)
	var max_row: int = 0
	var max_column: float = 0.0
	for talent in tree.talents:
		var button := TalentButton.new()
		button.setup(talent)
		button.position = Vector2(PADDING + talent.column * CELL, TITLE_HEIGHT + PADDING + talent.row * CELL)
		button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		add_child(button)
		buttons[talent] = button
		max_row = max(max_row, talent.row)
		max_column = max(max_column, talent.column)
	custom_minimum_size = Vector2(PADDING * 2 + max_column * CELL + BUTTON_SIZE, TITLE_HEIGHT + PADDING * 2 + max_row * CELL + BUTTON_SIZE)
	PlayerState.talents_changed.connect(refresh)
	refresh()

func refresh() -> void:
	for button in buttons.values():
		button.refresh()
	queue_redraw()

func _draw() -> void:
	if tree.background:
		draw_texture_rect(tree.background, Rect2(Vector2.ZERO, size), false)
	for talent in tree.talents:
		for parent in talent.parents:
			if not buttons.has(parent):
				continue
			var from: Vector2 = buttons[parent].position + Vector2(BUTTON_SIZE / 2.0, BUTTON_SIZE)
			var to: Vector2 = buttons[talent].position + Vector2(BUTTON_SIZE / 2.0, 0.0)
			var maxed: bool = PlayerState.talent_rank(parent) >= parent.max_ranks
			draw_line(from, to, Color(1.0, 0.85, 0.3) if maxed else Color(0.4, 0.4, 0.4), 3.0)
