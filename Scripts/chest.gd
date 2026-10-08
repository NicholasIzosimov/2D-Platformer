class_name Chest
extends Prop

@export var loot: LootTable
@export var item_rules: ItemRules
@export var min_rarity: Rarity
enum State {CLOSED, FULL, EMPTY}
var state: State = State.CLOSED
var contents: LootContents

func _ready() -> void:
	super._ready()
	$Interactable.interacted.connect(_on_interacted)
	show_state()

func _on_interacted(_unit: Node) -> void:
	if state == State.CLOSED:
		contents = LootContents.roll(loot, item_rules, PlayerState.level, min_rarity)
		set_state(State.FULL)
		$Sprite.play("opening")
		return
	for i in contents.entries.size():
		contents.take(i)
	if contents.is_empty():
		set_state(State.EMPTY)
		show_state()

func set_state(new_state: State) -> void:
	state = new_state
	$Interactable.enabled = state != State.EMPTY
	if state == State.EMPTY:
		$Interactable.set_highlight(false)

func show_state() -> void:
	match state:
		State.CLOSED:
			$Sprite.play("closed")
		State.FULL:
			$Sprite.play("full")
		State.EMPTY:
			$Sprite.play("empty")
