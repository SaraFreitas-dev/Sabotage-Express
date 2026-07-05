extends Node2D

const TILE_SIZE := 70
const ORIGINAL_TILE_SIZE := 154

# Declare the images
@export var corner_tile: Texture2D
@export var edge_tile: Texture2D
@export var normal_tile: Texture2D

# Vertical position of the grid
# Change this value to move the grid down or down
@export var grid_y_position: float = 180.0

var grid_width: int
var grid_height: int


func build_grid(width: int, height: int) -> void:
	grid_width = width
	grid_height = height
	occupied_cells.clear() # CLEAN PREVIOUS CABLES
	
	# Clean the previous grid board
	for child in get_children():
		child.queue_free()
	
	# Center the whole grid horizontally
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

			# Position by center of each cell, local to Tiles_grid
			sprite.position = Vector2(
				x * TILE_SIZE + TILE_SIZE / 2,
				y * TILE_SIZE + TILE_SIZE / 2
			)

			add_child(sprite)


# To center the grid alongside the cables panel:
# Calculate the size of the grid
func get_grid_size() -> Vector2:
	return Vector2(grid_width * TILE_SIZE, grid_height * TILE_SIZE)


# Calculate the center of the grid
func get_grid_center_global() -> Vector2:
	return global_position + get_grid_size() / 2.0


func get_tile_texture(x: int, y: int, w: int, h: int) -> Texture2D:
	# Choose the correct image depending on the location of the grid
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

	# Corners - Rotate images if needed
	# tile_border_corners.png = top-left corner
	if is_top and is_left:
		return 0.0
	if is_top and is_right:
		return 90.0
	if is_bottom and is_right:
		return 180.0
	if is_bottom and is_left:
		return 270.0

	# Edges - Rotate images if needed
	# grid_tile_edge.png = left edge
	if is_left:
		return 0.0
	if is_top:
		return 90.0
	if is_right:
		return 180.0
	if is_bottom:
		return 270.0

	return 0.0


# Get the grid tiles positions to add the dinamite and extra pieces / decor
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


# To prevent adding pieces outside of the grid
func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < grid_width
		and cell.y >= 0
		and cell.y < grid_height
	)

# FOR THE CABLES
var occupied_cells: Dictionary = {}  # Vector2i -> piece node

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func occupy_cell(cell: Vector2i, piece: Node) -> void:
	occupied_cells[cell] = piece

func free_cell(cell: Vector2i) -> void:
	occupied_cells.erase(cell)

""" For tests only !!!! Build a grid while there is no JSON
func _ready() -> void:
	build_grid(9, 7)
"""
