extends TextureButton

func _ready():
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_pressed)

func _on_pressed():
	pass  # TAI: connect to menu scene

func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)

func _on_unhover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
