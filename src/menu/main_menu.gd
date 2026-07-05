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

const FIRST_LEVEL_SCENE := "res://src/level_base.tscn"
const CUSTOM_CURSOR: Texture2D = preload("res://Images/menu/mouse.png")

@onready var start_button: Button = $StartButton
@onready var instructions_button: Button = $InstructionsButton
@onready var quit_button: Button = $QuitButton
@onready var instructions_panel: Control = get_node_or_null("InstructionsPanel")


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	if instructions_panel:
		instructions_panel.visible = false
	# Use the menu's custom cursor image while in the menu.
	Input.set_custom_mouse_cursor(CUSTOM_CURSOR)


func _on_start_pressed() -> void:
	# Restore the default cursor before leaving the menu.
	Input.set_custom_mouse_cursor(null)
	get_tree().change_scene_to_file(FIRST_LEVEL_SCENE)


func _on_instructions_pressed() -> void:
	if instructions_panel:
		instructions_panel.visible = not instructions_panel.visible


func _on_quit_pressed() -> void:
	get_tree().quit()
