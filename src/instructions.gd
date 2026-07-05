extends Node2D

@onready var image: Sprite2D = $Sprite2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 999

	get_tree().paused = true

	var viewport_size: Vector2 = get_viewport_rect().size
	var texture_size: Vector2 = image.texture.get_size()

	var camera: Camera2D = get_viewport().get_camera_2d()

	if camera != null:
		global_position = camera.get_screen_center_position()
	else:
		global_position = viewport_size / 2.0

	var scale_x: float = viewport_size.x / texture_size.x
	var scale_y: float = viewport_size.y / texture_size.y
	var final_scale: float = max(scale_x, scale_y)

	image.centered = true
	image.position = Vector2.ZERO
	image.scale = Vector2(final_scale, final_scale)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		queue_free()

func _exit_tree() -> void:
	get_tree().paused = false
