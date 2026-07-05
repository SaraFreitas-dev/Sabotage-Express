# Make the honey badger centered to the left of the grid's position
extends Node2D
signal detonate_finished

@export var honey_gap: float = -80.0 # Left distance from the grid
@export var honey_width: float = 300
@export var vertical_offset: float = -100.0 # To center the detonator on the start position tile

@onready var badger_animation: AnimatedSprite2D = $badger_animation

func _ready() -> void:
	badger_animation.play("honey_badger_playing")

func align_with_grid(tiles_grid: Node2D) -> void:
	var grid_size: Vector2 = tiles_grid.get_grid_size()
	var grid_left: float = tiles_grid.global_position.x
	var grid_center_y: float = tiles_grid.global_position.y + grid_size.y / 2.0
	global_position = Vector2(
		grid_left - honey_gap - honey_width / 2.0,
		grid_center_y + vertical_offset
	)


# IF YOU WIN THE GAME - CHANGE ANIMATION TO DETONATE THE DYNAMITE
func play_detonate_animation() -> void:
	badger_animation.sprite_frames.set_animation_loop("honey_badger_detonator", false)
	badger_animation.play("honey_badger_detonator")
	if not badger_animation.animation_finished.is_connected(_on_detonate_animation_finished):
		badger_animation.animation_finished.connect(_on_detonate_animation_finished)
		
		
func _on_detonate_animation_finished() -> void:
	badger_animation.animation_finished.disconnect(_on_detonate_animation_finished)
	detonate_finished.emit()
