extends TextureButton


func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func _on_pressed():
	var train = get_tree().current_scene.get_node("Train")
	var train_sounds = get_tree().current_scene.get_node("Train_Sounds")
	
	train_sounds.stop()
	train.reset()
	train.start_moving()
	LevelManager.reset_current_level()


func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)


func _on_unhover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
