# Place the dinamite on the correct location of the grid
extends Node2D

func align_with_grid(tiles_grid: Node2D, target_cell: Vector2i) -> void:
	position = tiles_grid.grid_to_world(target_cell.x, target_cell.y)
	
	var target_size := 95.0
	var sprite: Sprite2D = $Dynamite_Img
	var tex_size := sprite.texture.get_size()
	
	sprite.scale = Vector2(
		target_size / tex_size.x,
		target_size / tex_size.y
	) * 0.9
