class_name Chest
extends Prop

@export var loot: LootTable
@export var gear_rules: GearRules
@export var min_rarity: Rarity
@export var title: String = "Chest"
enum State {CLOSED, FULL, EMPTY}
var state: State = State.CLOSED
var contents: LootContents

func _ready() -> void:
	super._ready()
	$Interactable.interacted.connect(_on_interacted)
	show_state()

func _on_interacted(_unit: Node) -> void:
	if state == State.CLOSED:
		contents = LootContents.roll(loot, gear_rules, PlayerState.level, min_rarity)
		contents.changed.connect(_on_contents_changed)
		set_state(State.FULL)
		$Sprite.play("opening")
	if contents.is_empty():
		_on_contents_changed()
		return
	get_tree().get_first_node_in_group("loot_window").open(contents, $Interactable, title)

func _on_contents_changed() -> void:
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

func save_state() -> Variant:
	return {"state": state, "contents": contents}

func load_state(data: Variant) -> void:
	contents = data.contents
	if contents:
		contents.changed.connect(_on_contents_changed)
	set_state(data.state)
	show_state()
