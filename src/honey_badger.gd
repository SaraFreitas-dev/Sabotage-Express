# Make the honey badger centered to the left of the grid's position
extends Node2D

@export var honey_gap: float = -80.0 # Left distance from the grid
@export var honey_width: float = 300
@export var vertical_offset: float = -100.0 # To center the detonator on the start position tile

func align_with_grid(tiles_grid: Node2D) -> void:
	var grid_size: Vector2 = tiles_grid.get_grid_size()
	var grid_left: float = tiles_grid.global_position.x
	var grid_center_y: float = tiles_grid.global_position.y + grid_size.y / 2.0

	global_position = Vector2(
		grid_left - honey_gap - honey_width / 2.0,
		grid_center_y + vertical_offset
	)
	
