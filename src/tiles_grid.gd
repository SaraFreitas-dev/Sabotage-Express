# grid.gd
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
	
	for child in get_children():
		child.queue_free()
	
	var screen_width := get_viewport_rect().size.x
	var grid_pixel_width := width * TILE_SIZE
	var start_x := (screen_width - grid_pixel_width) / 2.0
	var start_y := grid_y_position
	
	for y in range(height):
		for x in range(width):
			var sprite := Sprite2D.new()
			var tex := get_tile_texture(x, y, width, height)
			sprite.texture = tex
			sprite.rotation_degrees = get_tile_rotation(x, y, width, height)
			
			# escala calculada por textura, força sempre TILE_SIZE x TILE_SIZE exato
			sprite.scale = Vector2(
				float(TILE_SIZE) / tex.get_width(),
				float(TILE_SIZE) / tex.get_height()
			)
			
			sprite.position = Vector2(
				start_x + x * TILE_SIZE + TILE_SIZE / 2,
				start_y + y * TILE_SIZE + TILE_SIZE / 2
			)
			add_child(sprite)


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

	# Corners
	# tile_border_corners.png = top-left corner
	if is_top and is_left:
		return 0.0
	if is_top and is_right:
		return 90.0
	if is_bottom and is_right:
		return 180.0
	if is_bottom and is_left:
		return 270.0

	# Edges
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
	
	
	
# For tests only !!!! While there is no JSON
func _ready() -> void:
	build_grid(7, 7)
