extends Node

var current_level: int = 1
var current_level_data: Dictionary = {}
var max_level: int = 3

signal level_loaded(data: Dictionary)

func load_level(level_number: int):
	current_level = level_number
	var path = "res://data/levels/level_%02d.json" % level_number
	
	if not FileAccess.file_exists(path):
		push_error("Nível não encontrado: " + path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Erro ao fazer parse do JSON: " + json.get_error_message())
		return
	
	current_level_data = json.data
	level_loaded.emit(current_level_data)

func go_to_next_level():
	if current_level < max_level:
		load_level(current_level + 1)
