extends Area2D

var piece_type: String = ""
var tiles_grid: Node2D = null
var cable_panel: Node2D = null
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Cable_IMG

func setup(type: String, texture: Texture2D, grid: Node2D, panel: Node2D, target_size: float = 55.0) -> void:
	piece_type = type
	tiles_grid = grid
	cable_panel = panel
	sprite.texture = texture
	
	var tex_size := texture.get_size()
	var scale_factor: float = target_size / max(tex_size.x, tex_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()

func _start_drag() -> void:
	dragging = true
	drag_offset = global_position - get_global_mouse_position()
	home_position = global_position
	z_index = 100

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

func _end_drag() -> void:
	dragging = false
	z_index = 0
	_try_place()

func _try_place() -> void:
	var cell: Vector2i = tiles_grid.world_to_grid(global_position)
	
	if tiles_grid.is_inside_grid(cell) and not tiles_grid.is_cell_occupied(cell):
		global_position = tiles_grid.grid_to_world(cell)
		tiles_grid.occupy_cell(cell, self)
		cable_panel.on_piece_placed(self)
	else:
		global_position = home_position
