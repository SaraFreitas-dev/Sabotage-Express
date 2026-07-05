extends Node2D
@export var panel_gap: float = 30.0
@export var panel_width: float = 200.0
@export var tiles_grid: Node2D
const PIECE_SCENE := preload("res://src/cable_piece.tscn")
const HAND_SIZE := 3
const SLOT_SPACING := 70.0
var pieces_data: Dictionary = {}
var original_pieces_data: Dictionary = {}
var current_hand: Array = []

func align_with_grid(grid: Node2D) -> void:
	var grid_size: Vector2 = grid.get_grid_size()
	var grid_left: float = grid.global_position.x
	var grid_right: float = grid_left + grid_size.x
	var grid_center_y: float = grid.global_position.y + grid_size.y / 2.0
	global_position = Vector2(
		grid_right + panel_gap + panel_width / 2.0,
		grid_center_y
	)

func setup_hand(pieces: Dictionary) -> void:
	pieces_data = pieces.duplicate(true)
	original_pieces_data = pieces.duplicate(true)
	_clear_hand()
	_fill_hand()

func _clear_hand() -> void:
	for piece in current_hand:
		if is_instance_valid(piece):
			piece.queue_free()
	current_hand.clear()

func _fill_hand() -> void:
	while current_hand.size() < HAND_SIZE:
		if not _has_pieces_left():
			_refill_pieces_data()
		_spawn_random_piece()
	_reposition_hand()

func _has_pieces_left() -> bool:
	for type in pieces_data.keys():
		if pieces_data[type]["amount"] > 0:
			return true
	return false

func _spawn_random_piece() -> void:
	var available_types: Array = []
	for type in pieces_data.keys():
		if pieces_data[type]["amount"] > 0:
			available_types.append(type)
	
	if available_types.is_empty():
		return
	
	var chosen_type: String = available_types[randi() % available_types.size()]
	var texture: Texture2D = load(pieces_data[chosen_type]["image"])
	
	var piece := PIECE_SCENE.instantiate()
	add_child(piece)
	piece.setup(chosen_type, texture, tiles_grid, self)
	
	pieces_data[chosen_type]["amount"] -= 1
	current_hand.append(piece)

func _refill_pieces_data() -> void:
	pieces_data = original_pieces_data.duplicate(true)

func _reposition_hand() -> void:
	var count := current_hand.size()
	var start_y := -(count - 1) * SLOT_SPACING / 2.0
	for i in range(count):
		current_hand[i].position = Vector2(0, start_y + i * SLOT_SPACING)

func on_piece_placed(piece: Node) -> void:
	current_hand.erase(piece)
	_fill_hand()
	
	if tiles_grid.check_win():
		on_win()

func on_win() -> void:
	var dynamite = get_tree().current_scene.get_node("Dynamite")
	var explosion = get_tree().current_scene.get_node("Explosion")  # ajusta o nome se for diferente
	explosion.play_explosion(dynamite.global_position)
