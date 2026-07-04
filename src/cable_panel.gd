# Make the panel centered to the right of the grid's position
extends Node2D

@export var panel_gap: float = 30.0
@export var panel_width: float = 200.0

func align_with_grid(tiles_grid: Node2D) -> void:
	var grid_size: Vector2 = tiles_grid.get_grid_size()

	var grid_left: float = tiles_grid.global_position.x
	var grid_right: float = grid_left + grid_size.x
	var grid_center_y: float = tiles_grid.global_position.y + grid_size.y / 2.0

	global_position = Vector2(
		grid_right + panel_gap + panel_width / 2.0,
		grid_center_y
	)
