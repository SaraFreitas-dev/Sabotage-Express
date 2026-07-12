extends TextureButton


func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func _on_pressed():
	get_tree().change_scene_to_file("res://src/menu/Intro.tscn")


func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)


func _on_unhover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
