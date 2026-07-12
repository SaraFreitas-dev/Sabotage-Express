extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if has_node("Background"):
		$Background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	z_index = 100

func show_popup() -> void:
	visible = true

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://src/menu/Intro.tscn")
