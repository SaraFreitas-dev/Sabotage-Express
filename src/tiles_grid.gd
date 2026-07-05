extends Node2D
const TILE_SIZE := 70
const ORIGINAL_TILE_SIZE := 154

@export var corner_tile: Texture2D
@export var edge_tile: Texture2D
@export var normal_tile: Texture2D
@export var grid_y_position: float = 180.0

var grid_width: int
var grid_height: int
var occupied_cells: Dictionary = {}  # Vector2i -> piece node
var detonator_entry: Vector2i = Vector2i.ZERO
var dynamite_exit: Vector2i = Vector2i.ZERO

const DIRS := {
	"up": Vector2i(0, -1),
	"right": Vector2i(1, 0),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
}
const DIR_ORDER := ["up", "right", "down", "left"]

# Aberturas de cada peça na rotação 0 
const PIECE_CONNECTIONS := {
	"straight": ["left", "right"],
	"elbow": ["down", "right"], 
	"tip": ["left"],
	"t-shape": ["left", "right", "up"],
	"cross": ["up", "right", "down", "left"],
}

func build_grid(width: int, height: int) -> void:
	grid_width = width
	grid_height = height
	
	# Remove any cable pieces still placed on the grid from a previous game
	for cell in occupied_cells.keys():
		var piece = occupied_cells[cell]
		if is_instance_valid(piece):
			piece.queue_free()
	occupied_cells.clear()
	
	for child in get_children():
		child.queue_free()
	
	var screen_width := get_viewport_rect().size.x
	var grid_pixel_width := width * TILE_SIZE
	position.x = (screen_width - grid_pixel_width) / 2.0
	position.y = grid_y_position
	
	for y in range(height):
		for x in range(width):
			var sprite := Sprite2D.new()
			sprite.texture = get_tile_texture(x, y, width, height)
			sprite.rotation_degrees = get_tile_rotation(x, y, width, height)
			var texture_size := sprite.texture.get_size()
			sprite.scale = Vector2(
				float(TILE_SIZE) / texture_size.x,
				float(TILE_SIZE) / texture_size.y
			)
			sprite.position = Vector2(
				x * TILE_SIZE + TILE_SIZE / 2,
				y * TILE_SIZE + TILE_SIZE / 2
			)
			add_child(sprite)

func set_endpoints(entry: Vector2i, exit: Vector2i) -> void:
	detonator_entry = entry
	dynamite_exit = exit

func get_grid_size() -> Vector2:
	return Vector2(grid_width * TILE_SIZE, grid_height * TILE_SIZE)

func get_grid_center_global() -> Vector2:
	return global_position + get_grid_size() / 2.0

func get_tile_size() -> float:
	return float(TILE_SIZE)

func get_tile_texture(x: int, y: int, w: int, h: int) -> Texture2D:
	var is_left := x == 0
	var is_right := x == w - 1
	var is_top := y == 0
	var is_bottom := y == h - 1
	var edges := int(is_left) + int(is_right) + int(is_top) + int(is_bottom)
	if edges >= 2:
		return corner_tile
	elif edges == 1:
		return edge_tile
	else:
		return normal_tile

func get_tile_rotation(x: int, y: int, w: int, h: int) -> float:
	var is_left := x == 0
	var is_right := x == w - 1
	var is_top := y == 0
	var is_bottom := y == h - 1
	if is_top and is_left:
		return 0.0
	if is_top and is_right:
		return 90.0
	if is_bottom and is_right:
		return 180.0
	if is_bottom and is_left:
		return 270.0
	if is_left:
		return 0.0
	if is_top:
		return 90.0
	if is_right:
		return 180.0
	if is_bottom:
		return 270.0
	return 0.0

func grid_to_world(cell: Vector2i) -> Vector2:
	return global_position + Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position - global_position
	return Vector2i(
		int(local_position.x / TILE_SIZE),
		int(local_position.y / TILE_SIZE)
	)

func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < grid_width
		and cell.y >= 0
		and cell.y < grid_height
	)

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func occupy_cell(cell: Vector2i, piece: Node) -> void:
	occupied_cells[cell] = piece

func free_cell(cell: Vector2i) -> void:
	occupied_cells.erase(cell)

func _opposite(dir: String) -> String:
	var idx := DIR_ORDER.find(dir)
	return DIR_ORDER[(idx + 2) % 4]

func _rotate_dir(dir: String, rot_degrees: float) -> String:
	var steps := int(round(rot_degrees / 90.0)) % 4
	var idx := DIR_ORDER.find(dir)
	return DIR_ORDER[(idx + steps) % 4]

func _get_piece_connections(piece: Node) -> Array:
	var base: Array = PIECE_CONNECTIONS.get(piece.piece_type, [])
	var rotated: Array = []
	for d in base:
		rotated.append(_rotate_dir(d, piece.rotation_degrees))
	return rotated


func check_win() -> bool:
	print("=== CHECK WIN ===")
	print("Entry: ", detonator_entry, " | Exit (dynamite): ", dynamite_exit)
	
	if not is_cell_occupied(detonator_entry):
		print("FALHA: entry não ocupada")
		return false
	
	var start_piece: Node = occupied_cells[detonator_entry]
	var start_connections: Array = _get_piece_connections(start_piece)
	print("Peça entrada: ", start_piece.piece_type, " rot:", start_piece.rotation_degrees, " conn:", start_connections)
	
	if not start_connections.has("left"):
		print("FALHA: peça entrada não liga 'left'")
		return false
	
	var exit_neighbor: Vector2i = dynamite_exit - DIRS["right"]
	print("Célula alvo (antes da dinamite): ", exit_neighbor)
	
	var visited: Dictionary = {}
	var queue: Array = [detonator_entry]
	visited[detonator_entry] = true
	
	while queue.size() > 0:
		var cell: Vector2i = queue.pop_front()
		var piece: Node = occupied_cells[cell]
		var connections: Array = _get_piece_connections(piece)
		print("Visitando ", cell, " peça:", piece.piece_type, " rot:", piece.rotation_degrees, " conn:", connections)
		
		if cell == exit_neighbor and connections.has("right"):
			return true
		
		for dir in connections:
			var neighbor: Vector2i = cell + DIRS[dir]
			if visited.has(neighbor):
				continue
			if not is_inside_grid(neighbor):
				continue
			if not is_cell_occupied(neighbor):
				print("  vizinho ", neighbor, " (", dir, ") vazio")
				continue
			
			var neighbor_piece: Node = occupied_cells[neighbor]
			var neighbor_connections: Array = _get_piece_connections(neighbor_piece)
			if neighbor_connections.has(_opposite(dir)):
				visited[neighbor] = true
				queue.append(neighbor)
			else:
				print("  vizinho ", neighbor, " não liga de volta (precisa ", _opposite(dir), ", tem ", neighbor_connections, ")")
	
	print("FALHA: não chegou à saída")
	return false


""" For tests only !!!! Build a grid while there is no JSON
func _ready() -> void:
	build_grid(9, 7)
"""
