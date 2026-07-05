extends Sprite2D


func _ready():
	visible = false
	top_level = true
	z_index = 100


func show_popup():
	var screen_size := get_viewport_rect().size
	
	global_position = screen_size / 2.0
	scale = Vector2(0.5, 0.5)
	visible = true


func _input(event):
	if visible and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://src/menu/Intro.tscn")
