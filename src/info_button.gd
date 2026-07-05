extends TextureButton


@onready var instructions_scene := preload("res://src/Instructions.tscn")
var instructions_instance: Node = null


func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func _on_pressed():
	if instructions_instance == null:
		instructions_instance = instructions_scene.instantiate()
		add_child(instructions_instance)

func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)


func _on_unhover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
