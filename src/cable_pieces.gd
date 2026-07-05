extends Area2D

# --- State ---
var piece_type: String = ""
var tiles_grid: Node2D = null
var cable_panel: Node2D = null
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO
var original_tex_size: Vector2 = Vector2.ZERO
var is_placed: bool = false

@onready var sprite: Sprite2D = $Cable_IMG
@onready var collision: CollisionShape2D = $CollisionShape2D


# Called once when the piece is spawned into the hand
func setup(type: String, texture: Texture2D, grid: Node2D, panel: Node2D, target_size: float = 55.0) -> void:
	piece_type = type
	tiles_grid = grid
	cable_panel = panel
	sprite.texture = texture
	
	original_tex_size = texture.get_size()
	var scale_factor: float = target_size / max(original_tex_size.x, original_tex_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	_update_collision_size(target_size)
	
	input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_press()
		else:
			_end_press()


# Mouse button pressed down on this piece
func _start_press() -> void:
	# Placed pieces should not be draggable, only rotatable
	if is_placed:
		return
	dragging = true
	drag_offset = global_position - get_global_mouse_position()
	home_position = global_position
	z_index = 100


func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset


# Mouse button released
func _end_press() -> void:
	if is_placed:
		_rotate_piece()
		return
	
	dragging = false
	z_index = 0
	_try_place()


# Rotate the piece 90 degrees clockwise and re-check the win condition
func _rotate_piece() -> void:
	rotation_degrees = fmod(rotation_degrees + 90.0, 360.0)
	if is_placed and tiles_grid.check_win():
		cable_panel.on_win()


# Attempt to place the piece into the grid cell under its current position
func _try_place() -> void:
	var cell: Vector2i = tiles_grid.world_to_grid(global_position)
	print(">>> Placing '", piece_type, "' at global_position: ", global_position, " -> calculated cell: ", cell)
	
	if tiles_grid.is_inside_grid(cell) and not tiles_grid.is_cell_occupied(cell):
		global_position = tiles_grid.grid_to_world(cell)
		tiles_grid.occupy_cell(cell, self)
		_resize_to_grid()
		is_placed = true
		cable_panel.on_piece_placed(self)
	else:
		# Invalid drop location, snap back to where it was picked up from
		global_position = home_position


# Resize the sprite (and its collision shape) to fill a full grid tile
func _resize_to_grid() -> void:
	var target_size: float = tiles_grid.get_tile_size()
	var scale_factor: float = target_size / max(original_tex_size.x, original_tex_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	_update_collision_size(target_size)


# Keep the collision shape in sync with the sprite's current size
func _update_collision_size(current_size: float) -> void:
	if collision.shape is RectangleShape2D:
		collision.shape.size = Vector2(current_size, current_size)
	elif collision.shape is CircleShape2D:
		collision.shape.radius = current_size / 2.0
		
