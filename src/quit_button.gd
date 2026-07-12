extends TextureButton

var highlight: ColorRect

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

	highlight = ColorRect.new()
	highlight.color = Color(0, 0, 0, 0)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(highlight)

func _on_pressed() -> void:
	get_tree().quit()

func _on_hover() -> void:
	var tween = create_tween()
	tween.tween_property(highlight, "color:a", 0.35, 0.08)

func _on_unhover() -> void:
	var tween = create_tween()
	tween.tween_property(highlight, "color:a", 0.0, 0.15)
 
 
