extends Control
## main_menu.gd
## Attached to the root node of Intro.tscn (the game's opening menu).
##
## NODE TREE:
##   Intro (Control, full rect)              <- this script
##     ├── Background (TextureRect)          -> Images/menu/menu.jpeg
##     ├── StartButton (Button)              -> "Play"
##     ├── InstructionsButton (Button)       -> "Instructions"
##     ├── QuitButton (Button)               -> "Quit"
##     └── InstructionsPanel (Panel, hidden by default) -> simple rules popup
##
## Flow: open the game -> this menu shows -> press "Play" -> the first phase
## of the main game (level_base.tscn) loads.
const FIRST_LEVEL_SCENE := "res://src/StoryIntro.tscn"
const CUSTOM_CURSOR: Texture2D = preload("res://Images/menu/mouse.png")

const HOVER_ALPHA := 0.35
const HOVER_IN_TIME := 0.08
const HOVER_OUT_TIME := 0.15

@onready var start_button: Button = $StartButton
@onready var instructions_button: Button = $InstructionsButton
@onready var quit_button: Button = $QuitButton
@onready var instructions_panel: Control = get_node_or_null("InstructionsPanel")

func _ready() -> void:
	print("MENU READY")
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_add_hover_effect(start_button)
	_add_hover_effect(instructions_button)
	_add_hover_effect(quit_button)

	if instructions_panel:
		instructions_panel.visible = false

	# Use the menu's custom cursor image while in the menu.
	Input.set_custom_mouse_cursor(CUSTOM_CURSOR)

# Adds a darkening overlay to any button that fades in on hover and
# fades out on unhover - same feeling as the lose popup buttons.
func _add_hover_effect(button: Control) -> void:
	var highlight := ColorRect.new()
	highlight.color = Color(0, 0, 0, 0)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Copy the button's exact anchors/offsets so the highlight matches its
	# rect precisely and stays responsive with it - but add it as a SIBLING,
	# not a child, so it doesn't inherit the button's own modulate (likely
	# set to alpha 0 to make it an invisible click zone over the static image).
	highlight.anchor_left = button.anchor_left
	highlight.anchor_top = button.anchor_top
	highlight.anchor_right = button.anchor_right
	highlight.anchor_bottom = button.anchor_bottom
	highlight.offset_left = button.offset_left
	highlight.offset_top = button.offset_top
	highlight.offset_right = button.offset_right
	highlight.offset_bottom = button.offset_bottom

	var parent := button.get_parent()
	parent.add_child(highlight)
	parent.move_child(highlight, button.get_index() + 1)

	button.mouse_entered.connect(func():
		print("HOVER IN: ", button.name, " rect_size=", button.size)
		var tween := create_tween()
		tween.tween_property(highlight, "color:a", HOVER_ALPHA, HOVER_IN_TIME)
	)
	button.mouse_exited.connect(func():
		print("HOVER OUT: ", button.name)
		var tween := create_tween()
		tween.tween_property(highlight, "color:a", 0.0, HOVER_OUT_TIME)
	)

func _on_start_pressed() -> void:
	# Restore the default cursor before leaving the menu.
	Input.set_custom_mouse_cursor(null)
	get_tree().change_scene_to_file(FIRST_LEVEL_SCENE)

func _on_instructions_pressed() -> void:
	if instructions_panel:
		instructions_panel.visible = not instructions_panel.visible

func _on_quit_pressed() -> void:
	get_tree().quit()
