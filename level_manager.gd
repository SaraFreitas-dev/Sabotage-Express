# level_manager.gd
extends Node

@export var level_to_load: int = 1
@export var levels_json_path: String = "res://data/levels_data.json"

# To align the elements
# NOTE: these used to be @onready vars resolved against get_tree().current_scene
# at autoload startup. Now that the game boots into the menu (Intro.tscn) first
# instead of directly into level_base.tscn, that scene doesn't exist yet when
# this autoload becomes ready, so the references are grabbed lazily instead,
# via start_level(), which is called once level_base.tscn actually becomes
# the current scene (see src/level_base.gd).
var tiles_grid: Node
var cables_panel: Node
var timer_panel: Node
var honey_badger: Node
var dynamite: Node
var current_level_data: Dictionary = {}


func start_level(level_number: int) -> void:
	# Called by level_base.gd once the level scene is fully loaded.
	var scene := get_tree().current_scene
	tiles_grid = scene.get_node("Tiles_grid")
	cables_panel = scene.get_node("Cable_Panel")
	timer_panel = scene.get_node("UI/Timer_Panel")
	honey_badger = scene.get_node("Honey_Badger")
	dynamite = scene.get_node("Dynamite")

	load_level(level_number)


func load_level(level_number: int) -> void:
	var levels_data := load_levels_json()


	if levels_data.is_empty():
		push_error("Levels JSON is empty or could not be loaded.")
		return

	var level_data := find_level_data(levels_data, level_number)

	if level_data.is_empty():
		push_error("Level %s not found in JSON." % level_number)
		return

	current_level_data = level_data

	var size: Array = level_data["size"]
	var grid_width: int = int(size[0])
	var grid_height: int = int(size[1])

	# Center / Add the elements
	tiles_grid.build_grid(grid_width, grid_height)
	
		# Define os pontos de entrada e saída para a lógica de vitória
	var entry_pos: Array = level_data["detonator_entry"]
	var exit_pos: Array = level_data["dynamite_exit"]
	tiles_grid.set_endpoints(
		Vector2i(int(entry_pos[0]), int(entry_pos[1])),
		Vector2i(int(exit_pos[0]), int(exit_pos[1]))
	)

	cables_panel.align_with_grid(tiles_grid)
	cables_panel.setup_hand(level_data["pieces"])  # TUBES
	honey_badger.align_with_grid(tiles_grid)
	timer_panel.start_countdown(level_data["time_limit"])
	
	# Get the dinamite pos
	var dynamite_pos: Array = level_data["dynamite_exit"]
	dynamite.align_with_grid(tiles_grid, Vector2i(dynamite_pos[0], dynamite_pos[1]))

	print("Loaded level: ", level_number)
	print("Grid size: ", grid_width, " x ", grid_height)
	print("Time limit: ", level_data["time_limit"])
	print("Detonator entry: ", level_data["detonator_entry"])
	print("Dynamite exit: ", level_data["dynamite_exit"])
	print("Blocked cells: ", level_data["blocked_cells"])
	print("Pieces: ", level_data["pieces"])
	print("Refreshes: ", level_data["refreshes"])


func load_levels_json() -> Dictionary:
	if not FileAccess.file_exists(levels_json_path):
		push_error("Levels JSON file not found: " + levels_json_path)
		return {}

	var file := FileAccess.open(levels_json_path, FileAccess.READ)

	if file == null:
		push_error("Could not open levels JSON file: " + levels_json_path)
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		push_error("JSON parse error: " + json.get_error_message())
		push_error("Error line: " + str(json.get_error_line()))
		return {}

	return json.data


func find_level_data(levels_data: Dictionary, level_number: int) -> Dictionary:
	if not levels_data.has("levels"):
		push_error("JSON does not contain 'levels'.")
		return {}

	for level in levels_data["levels"]:
		if int(level["level"]) == level_number:
			return level

	return {}


# FOR THE RESET BUTTON - RELOAD JSON
func reset_current_level() -> void:
	print("RESET CURRENT LEVEL CALLED")
	print("Current level data: ", current_level_data)

	if current_level_data.is_empty():
		push_error("No current level loaded to reset.")
		return

	var level_number: int = int(current_level_data["level"])
	print("Resetting level: ", level_number)

	load_level(level_number)
