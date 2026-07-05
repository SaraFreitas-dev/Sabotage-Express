extends TextureButton

@onready var instructions_scene := preload("res://src/Instructions.tscn")
@onready var timer_ui: Control = $"../../Timer_Panel"

var instructions_instance: Node = null
var buttons_container: Node = null

func _ready() -> void:
	buttons_container = get_parent()

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func _on_pressed() -> void:
	release_focus()

	if instructions_instance != null:
		return

	instructions_instance = instructions_scene.instantiate()
	get_tree().current_scene.add_child(instructions_instance)

	buttons_container.visible = false
	timer_ui.visible = false

	instructions_instance.tree_exited.connect(func():
		instructions_instance = null
		buttons_container.visible = true
		timer_ui.visible = true
	)

func _on_hover() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)

func _on_unhover() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
