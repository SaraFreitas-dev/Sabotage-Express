extends Node2D

# Carrega o script Pipe diretamente
const Pipe = preload("res://src/pipe_logic/pipe.gd")

@export var pipe_scene: PackedScene
@export var tex_straight: Texture2D
@export var tex_curve: Texture2D
@export var tex_cross: Texture2D
@export var tex_t: Texture2D
@export var tex_termination: Texture2D
@export var wood_texture: Texture2D
@export var grid_manual_offset: Vector2 = Vector2(0, 0)
@export var pipe_scale: Vector2 = Vector2(0.57, 0.57)
@export var manual_offset_x: float = 0.0
@export var manual_offset_y: float = 0.0

const OBSTACLE = "blocked"

var pipe_scene_loaded
var grid: Array = []
var cell_size: int = 70
var offset_x: float = 0
var offset_y: float = 0

# ---- Inventário ----
var inventory_pieces: Array = []
var upcoming_pieces: Array = []
var inventory_slots: Array = []
var inventory_instances: Array = []
var is_dragging_from_inventory: bool = false
var drag_inventory_index: int = -1

# ---- Controles de drag ----
var dragging_pipe: Pipe = null
var drag_original_grid_pos: Vector2i = Vector2i(-1, -1)
var drag_offset: Vector2 = Vector2()
var is_dragging: bool = false
var click_timer: float = 0.0
var click_pipe: Pipe = null
var is_waiting_for_click: bool = false
const CLICK_DELAY: float = 0.15

# ---- CONTROLE DE RECURSÃO ----
var is_checking_circuit: bool = false

func _ready() -> void:
#	create_inventory()
#	_print_grid_state()
	pass

func _process(delta: float) -> void:
	if dragging_pipe != null and not is_dragging_from_inventory:
		dragging_pipe.global_position = get_global_mouse_position() - drag_offset
	
	if is_dragging_from_inventory and drag_inventory_index >= 0:
		var pipe = inventory_instances[drag_inventory_index]
		if pipe != null:
			pipe.global_position = get_global_mouse_position() - drag_offset
	
	if is_waiting_for_click:
		click_timer += delta
		if click_timer > CLICK_DELAY and click_pipe != null:
			if not _is_fixed_pipe(click_pipe):
				click_pipe.rotate_pipe_clockwise()
			click_pipe = null
			is_waiting_for_click = false
			click_timer = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_global_mouse_position()
			
			var inv_index = _get_inventory_pipe_at_mouse(mouse_pos)
			if inv_index >= 0:
				_start_drag_from_inventory(inv_index)
				return
			
			var pipe = _get_pipe_at_mouse()
			if pipe != null:
				if _is_fixed_pipe(pipe):
					return
				if pipe.type in [1, 2]:
					return
				
				click_pipe = pipe
				is_waiting_for_click = true
				click_timer = 0.0
				drag_offset = get_global_mouse_position() - pipe.global_position
		else:
			if is_dragging_from_inventory:
				_finish_drag_from_inventory()
			elif dragging_pipe != null and is_dragging:
				_finish_drag(dragging_pipe)
			elif is_waiting_for_click:
				if click_pipe != null and not _is_fixed_pipe(click_pipe):
					click_pipe.rotate_pipe_clockwise()
				click_pipe = null
				is_waiting_for_click = false
				click_timer = 0.0
			
			dragging_pipe = null
			is_dragging = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var dist = event.relative.length()
		if dist > 5.0:
			if is_dragging_from_inventory and drag_inventory_index >= 0:
				pass
			elif is_waiting_for_click and click_pipe != null:
				if not _is_fixed_pipe(click_pipe):
					is_waiting_for_click = false
					click_timer = 0.0
					_start_drag(click_pipe)
					click_pipe = null

func _is_fixed_pipe(pipe: Pipe) -> bool:
	if pipe == null:
		return true
	
	# Agora ele verifica se a peça foi marcada como fixa!
	if pipe.is_fixed:
		return true
		
	return false

func _get_pipe_at_mouse() -> Object:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = _global_to_grid(mouse_pos)
	
	if grid_pos.x >= 0 and grid_pos.x < grid[0].size() and \
	   grid_pos.y >= 0 and grid_pos.y < grid.size():
		return grid[grid_pos.y][grid_pos.x]
	return null

func _get_inventory_pipe_at_mouse(mouse_pos: Vector2) -> int:
	for i in range(inventory_instances.size()):
		var pipe = inventory_instances[i]
		if pipe != null:
			var pipe_rect = Rect2(pipe.global_position - Vector2(cell_size/2, cell_size/2), Vector2(cell_size, cell_size))
			if pipe_rect.has_point(mouse_pos):
				return i
	return -1

func _get_base_connections(piece_type: int) -> Array:
	match piece_type:
		1, 2, 3:
			return [false, true, false, true]
		4:
			return [false, true, true, false]
		5:
			return [false, true, true, true]
		6:
			return [true, true, true, true]
		7:
			return [false, false, false, true]
		_:
			return [false, false, false, false]

func _rotate_connections(connections: Array, times: int) -> Array:
	var result = connections.duplicate()
	for i in range(times):
		var last = result[3]
		result[3] = result[2]
		result[2] = result[1]
		result[1] = result[0]
		result[0] = last
	return result

func _get_texture_for_type(piece_type: int) -> Texture2D:
	match piece_type:
		1, 2, 3:
			return tex_straight
		4:
			return tex_curve
		5:
			return tex_t
		6:
			return tex_cross
		7:
			return tex_termination
		_:
			return tex_straight

func _count_empty_cells() -> int:
	var count = 0
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == null:
				count += 1
	return count

func _count_inventory_pieces() -> int:
	var count = 0
	for pipe in inventory_instances:
		if pipe != null:
			count += 1
	return count

func _print_grid_state() -> void:
	print("=== GRID STATE ===")
	for y in range(grid.size()):
		var row = ""
		for x in range(grid[y].size()):
			if grid[y][x] == null:
				row += "[ ] "
			else:
				row += "[" + str(grid[y][x].type) + "] "
		print(row)
	print("Empty cells: ", _count_empty_cells())
	print("Inventory pieces: ", _count_inventory_pieces())
	print("===================")

func create_board(level_data: Dictionary) -> void:
	var detonator_pos = [int(level_data["detonator_entry"][0]), int(level_data["detonator_entry"][1])]
	var dynamite_pos = [int(level_data["dynamite_exit"][0]), int(level_data["dynamite_exit"][1])]
	# --- LIMPEZA DE SEGURANÇA ---
	if level_data.is_empty():
		push_error("ERRO: level_data chegou vazio no create_board!")
		return

	for child in get_children():
		if child.has_method("set_pipe_data"): # Remove apenas os Pipes
			child.queue_free()
	inventory_pieces = level_data.get("inventory_pieces", [])
	upcoming_pieces = level_data.get("upcoming_pieces", [])
	# 1. Obter dados do nível
	var size: Array = level_data["size"]
	var grid_width: int = int(size[0])
	var grid_height: int = int(size[1])
	
	# 2. Limpar grid antigo, se houver
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != null:
				grid[y][x].queue_free()
	grid = []

	# 3. Configurar offset e tamanho (usando o tiles_grid se disponível)
	# Aqui assumimos que o tiles_grid já foi configurado pelo level_manager
	var screen_size = get_viewport_rect().size
	var total_width = grid_width * cell_size
	var total_height = grid_height * cell_size
	
	offset_x = (screen_size.x - total_width) / 2.0
	offset_y = (screen_size.y - total_height) / 2.0
	
	pipe_scene_loaded = load("res://src/pipe_logic/pipe.tscn")

	# 4. Criar matriz lógica baseada no tamanho do JSON
	for y in range(grid_height):
		grid.append([])
		for x in range(grid_width):
			# Verifica se a célula está bloqueada
			var is_blocked = false
			for blocked in level_data["blocked_cells"]:
				if int(blocked[0]) == x and int(blocked[1]) == y:
					is_blocked = true
					break
			
			if is_blocked:
				grid[y].append(OBSTACLE) # Ou coloque um objeto de "Obstáculo"
				print("Bloqueado adicionado em: ", x, ", ", y)
				continue
			
			if x == detonator_pos[0] and y == detonator_pos[1]:
				grid[y].append(_spawn_fixed_pipe({"type": 1, "rotation": 0}, x, y))
				continue
				
			if x == dynamite_pos[0] and y == dynamite_pos[1]:
				grid[y].append(_spawn_fixed_pipe({"type": 2, "rotation": 0}, x, y))
				continue
			# (Aqui você pode adicionar lógica para peças pré-posicionadas se desejar)
			var piece_data = _get_fixed_piece_data_at(x, y, level_data)
			if not piece_data.is_empty():
				var new_fixed = _spawn_fixed_pipe(piece_data, x, y)
				grid[y].append(new_fixed)
				continue
			# 👆 FIM DA LÓGICA DE PEÇAS FIXAS 👆

			grid[y].append(null)
	
	create_inventory()

	print("=== BOARD CREATED ===")
	print("Grid dimensions: ", grid_width, "x", grid_height)
	print("Level data loaded successfully.")
	print("=====================")

func _get_fixed_piece_type_at(x: int, y: int, level_data: Dictionary) -> int:
	# Verifica se existe a lista de peças fixas no seu JSON
	if not level_data.has("fixed_pieces"):
		return 0
		
	for piece in level_data["fixed_pieces"]:
		if piece["x"] == x and piece["y"] == y:
			return piece["type"]
	return 0

func _on_pipe_rotated() -> void:
	# Evita recursão infinita
	if not is_checking_circuit:
		check_circuit()

func create_inventory() -> void:
	# 1. Defina posições fixas (ajuste os valores conforme necessário para a sua placa)
	var inventory_start_x = 1086 
	var inventory_start_y = 335
	
	# 2. Limpa inventário anterior se necessário
	inventory_instances.clear()
	inventory_slots.clear()
	
	for i in range(inventory_pieces.size()):
		# DEFINA a variável AQUI, logo no início do ciclo
		var piece_type = inventory_pieces[i] 
		
		var new_pipe = pipe_scene_loaded.instantiate()
		add_child(new_pipe)
		
		# Posição baseada no início da placa
		var x_pos = inventory_start_x
		var y_pos = inventory_start_y + (i * (cell_size * 1.1))
		
		# Atribuições corretas usando a variável definida acima
		new_pipe.type = piece_type
		new_pipe.position = Vector2(x_pos, y_pos)
		new_pipe.scale = pipe_scale
		
		new_pipe.pipe_rotated.connect(_on_pipe_rotated)
		
		var texture = _get_texture_for_type(piece_type)
		var base_connections = _get_base_connections(piece_type)
		new_pipe.set_pipe_data(texture, base_connections)
		new_pipe.randomize_rotation()
		
		inventory_instances.append(new_pipe)
		inventory_slots.append(Vector2i(x_pos, y_pos))

func _spawn_new_inventory_piece(piece_type: int, slot_index: int) -> void:
	var new_pipe = pipe_scene_loaded.instantiate()
	add_child(new_pipe)
	
	var pos = inventory_slots[slot_index]
	new_pipe.position = Vector2(pos.x, pos.y)
	new_pipe.type = piece_type
	new_pipe.scale = pipe_scale
	new_pipe.pipe_rotated.connect(_on_pipe_rotated)
	
	var texture = _get_texture_for_type(piece_type)
	var base_connections = _get_base_connections(piece_type)
	new_pipe.set_pipe_data(texture, base_connections)
	new_pipe.randomize_rotation()
	
	# Coloca a nova peça na matriz do inventário
	inventory_instances[slot_index] = new_pipe

# ---- Drag do Grid ----
func _start_drag(piece: Pipe) -> void:
	if piece.type in [1, 2]:
		return
	if _is_fixed_pipe(piece):
		return

	dragging_pipe = piece
	drag_original_grid_pos = _find_pipe_grid_position(piece)
	drag_offset = Vector2(0, 0)
	
	if drag_original_grid_pos == Vector2i(-1, -1):
		dragging_pipe = null
		return

	grid[drag_original_grid_pos.y][drag_original_grid_pos.x] = null
	
	piece.z_index = 10
	var root = get_tree().current_scene
	remove_child(piece)
	root.add_child(piece)
	
	is_dragging = true

func _finish_drag(piece: Pipe) -> void:
	if dragging_pipe == null:
		return

	var mouse_pos = get_global_mouse_position()
	var new_grid_pos = _global_to_grid(mouse_pos)

	# Aqui nós definimos o valor de can_place
	var can_place = _is_cell_available(new_grid_pos)

	# Agora usamos essa variável UMA ÚNICA VEZ
	if can_place:
		_place_piece_at(piece, new_grid_pos)
	else:
		_restore_piece(piece, drag_original_grid_pos)

	dragging_pipe = null
	is_dragging = false
	check_circuit()

# ---- Drag do Inventário ----

func _start_drag_from_inventory(index: int) -> void:
	if index < 0 or index >= inventory_instances.size():
		return
	
	var piece = inventory_instances[index]
	if piece == null:
		return
	
	is_dragging_from_inventory = true
	drag_inventory_index = index
	drag_offset = get_global_mouse_position() - piece.global_position
	
	piece.z_index = 100	
	var root = get_tree().current_scene
	remove_child(piece)
	root.add_child(piece)

func _finish_drag_from_inventory() -> void:
	if not is_dragging_from_inventory or drag_inventory_index < 0:
		return
	
	var piece = inventory_instances[drag_inventory_index]
	if piece == null:
		is_dragging_from_inventory = false
		return
	
	var mouse_pos = get_global_mouse_position()
	var new_grid_pos = _global_to_grid(mouse_pos)
	print("Tentando soltar peça em grid: ", new_grid_pos, " Mouse global: ", mouse_pos)
	
	# Aqui definimos o valor de can_place
	var can_place = _is_cell_available(new_grid_pos)
	
	# Usamos apenas uma vez:
	if can_place:
		_place_piece_at(piece, new_grid_pos)
		
		# --- SISTEMA DE REPOSIÇÃO ---
		if upcoming_pieces.size() > 0:
			var next_piece_type = upcoming_pieces.pop_front()
			_spawn_new_inventory_piece(next_piece_type, drag_inventory_index)
		else:
			inventory_instances[drag_inventory_index] = null
	else:
		_restore_inventory_piece(piece, drag_inventory_index)
	
	is_dragging_from_inventory = false
	drag_inventory_index = -1
	check_circuit()

func _restore_inventory_piece(piece: Pipe, index: int) -> void:
	if index < 0 or index >= inventory_slots.size():
		return
	
	if piece.get_parent() != self:
		var root = get_tree().current_scene
		root.remove_child(piece)
		add_child(piece)
	
	var pos = inventory_slots[index]
	piece.position = Vector2(pos.x, pos.y)
	piece.z_index = 0
	inventory_instances[index] = piece

# ---- Funções Auxiliares ----

func _restore_piece(piece: Pipe, grid_pos: Vector2i) -> void:
	if piece.get_parent() != self:
		var root = get_tree().current_scene
		root.remove_child(piece)
		add_child(piece)
	piece.position = Vector2(
		grid_pos.x * cell_size + offset_x + (cell_size / 2.0) + manual_offset_x, 
		grid_pos.y * cell_size + offset_y + (cell_size / 2.0) + manual_offset_y
	)
	piece.z_index = 0
	grid[grid_pos.y][grid_pos.x] = piece

func _find_pipe_grid_position(piece: Pipe) -> Vector2i:
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == piece:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _global_to_grid(global_pos: Vector2) -> Vector2i:
	var x = floor((global_pos.x - offset_x) / cell_size)
	var y = floor((global_pos.y - offset_y) / cell_size)
	return Vector2i(x, y)

func _place_piece_at(piece: Pipe, grid_pos: Vector2i) -> void:
	# 1. Ajuste a hierarquia
	if piece.get_parent() != self:
		var root = get_tree().current_scene
		if piece.get_parent(): piece.get_parent().remove_child(piece)
		add_child(piece)
	
	# 2. Cálculo de posição
	var world_pos = Vector2(
		grid_pos.x * cell_size + offset_x + (cell_size / 2.0) + manual_offset_x, 
		grid_pos.y * cell_size + offset_y + (cell_size / 2.0) + manual_offset_y
	)
	
	piece.position = world_pos
	piece.z_index = 0
	piece.visible = true # FORÇAR VISIBILIDADE
	
	# 3. Atualiza o grid
	grid[grid_pos.y][grid_pos.x] = piece
	
	# 4. Debug visual
	print("Peça posicionada no grid ", grid_pos, " em World: ", world_pos)
	
	# 5. Limpa inventário
	for i in range(inventory_instances.size()):
		if inventory_instances[i] == piece:
			inventory_instances[i] = null
			break

func check_circuit() -> void:
	# Evita recursão infinita
	if is_checking_circuit:
		return
	
	is_checking_circuit = true
	
	var inv_pieces = _count_inventory_pieces() + upcoming_pieces.size()
	
#	print("=== CHECKING CIRCUIT ===")
#	print("Inventory pieces: ", inv_pieces)
	
#	if empty_cells > 0:
#		print("❌ Still have empty cells to fill!")
#		_print_grid_state()
#		is_checking_circuit = false
#		return
	
	if inv_pieces > 0:
#		print("❌ Still have pieces in inventory!")
		is_checking_circuit = false
		return
	
#	print("✅ All cells filled and inventory empty!")
	
	var start_pos = Vector2i(-1, -1)
	var end_pos = Vector2i(-1, -1)
	
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pipe = grid[y][x]
			if pipe != null:
				if pipe.type == 1: start_pos = Vector2i(x, y)
				if pipe.type == 2: end_pos = Vector2i(x, y)
	
	if start_pos == Vector2i(-1, -1) or end_pos == Vector2i(-1, -1):
		print("❌ Start or End not found!")
		is_checking_circuit = false
		return
	
	var queue: Array[Vector2i] = [start_pos]
	var visited: Array[Vector2i] = []
	var reached_end = false
	var has_leak = false
	
	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var opposites = [2, 3, 0, 1]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current in visited: continue
		visited.append(current)
		
		if current == end_pos:
			reached_end = true
		
		var current_pipe = grid[current.y][current.x]
		if current_pipe == null: 
			continue

		for i in range(4):
			if current_pipe.connections[i]:
				var neighbor_pos = current + directions[i]
				var valid_connection = false
				if neighbor_pos.y >= 0 and neighbor_pos.y < grid.size() and \
				   neighbor_pos.x >= 0 and neighbor_pos.x < grid[0].size():
					var neighbor_pipe = grid[neighbor_pos.y][neighbor_pos.x]
					if neighbor_pipe != null and neighbor_pipe.connections[opposites[i]]:
						valid_connection = true
						if not neighbor_pos in visited:
							queue.append(neighbor_pos)

				if not valid_connection:
					if current_pipe.type not in [1, 2]:
						has_leak = true
	
	var total_active_pieces = 0
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != null:
				total_active_pieces += 1
	
#	print("Reached end: ", reached_end)
#	print("Visited cells: ", visited.size())
#	print("Total active pieces: ", total_active_pieces)
#	print("Has leak: ", has_leak)
	
	if reached_end and visited.size() == total_active_pieces and not has_leak:
		print("💥 EXPLOSION! The bomb has been activated successfully!")
		_activate_bomb()
#	else:
#		print("❌ Circuit incomplete. Keep trying!")
	
	is_checking_circuit = false

func _activate_bomb() -> void:
	print("💥 BOOOOM! You won the game!")
	
	var label = Label.new()
	label.text = "💥 VICTORY! 💥"
	label.position = get_viewport_rect().size / 2 - Vector2(100, 20)
	label.scale = Vector2(2, 2)
	label.add_theme_color_override("font_color", Color.RED)
	add_child(label)

func _spawn_fixed_pipe(data, grid_x: int, grid_y: int) -> Pipe:
	var new_pipe = pipe_scene_loaded.instantiate()
	add_child(new_pipe)
	new_pipe.is_fixed = true
	
	var tiles_grid = get_tree().current_scene.get_node("Tiles_grid")
	new_pipe.global_position = tiles_grid.grid_to_world(grid_x, grid_y)

	# SEGURANÇA: Verifica se 'data' é um Dictionary antes de acessar
	var p_type = 0
	var p_rot = 0
	
	if typeof(data) == TYPE_DICTIONARY:
		p_type = data.get("type", 0)
		p_rot = data.get("rotation", 0)
	elif typeof(data) == TYPE_INT:
		p_type = data # Caso ainda esteja vindo um número solto de algum lugar
	
	new_pipe.type = p_type
	new_pipe.scale = pipe_scale
	
	# Aplica rotação
	for i in range(p_rot):
		new_pipe.rotate_pipe_clockwise()
	
	# Configura dados visuais
	new_pipe.visible = true
	var texture = _get_texture_for_type(p_type)
	var base_connections = _get_base_connections(p_type)
	new_pipe.set_pipe_data(texture, base_connections)
	
	return new_pipe

func _get_fixed_piece_data_at(x: int, y: int, level_data: Dictionary) -> Dictionary:
	if not level_data.has("fixed_pieces"):
		return {} # Retorna vazio se não houver peça
		
	for piece in level_data["fixed_pieces"]:
		if int(piece["x"]) == x and int(piece["y"]) == y:
			return piece
	return {} # Retorna vazio se não encontrar

func _is_cell_available(grid_pos: Vector2i) -> bool:
	# 1. Verifica limites
	if grid_pos.x < 0 or grid_pos.x >= grid[0].size() or \
	   grid_pos.y < 0 or grid_pos.y >= grid.size():
		return false
	
	var content = grid[grid_pos.y][grid_pos.x]
	
	# 2. Se for null, está livre
	if content == null:
		return true
	
	if content == "BLOCK":
		return false # Impede colocar peça em local bloqueado
		
	# 3. SE NÃO FOR NULL, vamos investigar o que tem ali
	print("Tentando colocar peça em: ", grid_pos, " mas o conteúdo é: ", content)
	
	# Se for uma peça fixa, não podemos colocar nada
	if content.has_method("is_fixed") and content.is_fixed == true:
		print("Bloqueado: Peça fixa em ", grid_pos)
		return false
		
	# Se for um obstáculo (você pode verificar se é um Node ou algo específico)
	return false
