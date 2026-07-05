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

var pipe_scene_loaded
var grid: Array = []
var cell_size: int = 84
var offset_x: float = 0
var offset_y: float = 0

# ---- Inventário ----
var inventory_pieces: Array = [3, 4, 7]
var upcoming_pieces: Array = [3, 3, 4, 3, 4, 3, 4]
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

func _get_pipe_at_mouse() -> Pipe:
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
	
	var detonator_pos = level_data["detonator_entry"]
	var dynamite_pos = level_data["dynamite_exit"]

	# 4. Criar matriz lógica baseada no tamanho do JSON
	for y in range(grid_height):
		grid.append([])
		for x in range(grid_width):
			# Verifica se a célula está bloqueada
			var is_blocked = false
			for blocked in level_data["blocked_cells"]:
				if blocked[0] == x and blocked[1] == y:
					is_blocked = true
					break
			
			if is_blocked:
				grid[y].append(null) # Ou coloque um objeto de "Obstáculo"
				continue
			
			if x == detonator_pos[0] and y == detonator_pos[1]:
				# Tipo 1 = Início (Detonator)
				var start_pipe = _spawn_fixed_pipe(1, x, y)
				grid[y].append(start_pipe)
				continue
				
			if x == dynamite_pos[0] and y == dynamite_pos[1]:
				# Tipo 2 = Fim (Dynamite)
				var end_pipe = _spawn_fixed_pipe(2, x, y)
				grid[y].append(end_pipe)
				continue
			# (Aqui você pode adicionar lógica para peças pré-posicionadas se desejar)
			var fixed_type = _get_fixed_piece_type_at(x, y, level_data)
			if fixed_type != 0:
				var new_fixed = _spawn_fixed_pipe(fixed_type, x, y)
				new_fixed.visible = true 
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
	var inventory_start_x = 1100 
	var inventory_start_y = 300
	
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
		var y_pos = inventory_start_y + (i * cell_size)
		
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

	var can_place = false
	if new_grid_pos.x >= 0 and new_grid_pos.x < grid[0].size() and \
	   new_grid_pos.y >= 0 and new_grid_pos.y < grid.size():
		if grid[new_grid_pos.y][new_grid_pos.x] == null:
			can_place = true

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
	
	piece.z_index = 10
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
	
	var can_place = false
	if new_grid_pos.x >= 0 and new_grid_pos.x < grid[0].size() and \
	   new_grid_pos.y >= 0 and new_grid_pos.y < grid.size():
		if grid[new_grid_pos.y][new_grid_pos.x] == null:
			can_place = true
	
	if can_place:
		_place_piece_at(piece, new_grid_pos)
		
		# --- SISTEMA DE REPOSIÇÃO (NOVO) ---
		if upcoming_pieces.size() > 0:
			# Pega a próxima peça da fila e remove ela da lista (pop_front)
			var next_piece_type = upcoming_pieces.pop_front()
			_spawn_new_inventory_piece(next_piece_type, drag_inventory_index)
		else:
			# Se a fila acabou, o espaço fica vazio de vez
			inventory_instances[drag_inventory_index] = null
		# -----------------------------------
		
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
	piece.position = Vector2(grid_pos.x * cell_size + offset_x, grid_pos.y * cell_size + offset_y)
	piece.z_index = 0
	grid[grid_pos.y][grid_pos.x] = piece

func _find_pipe_grid_position(piece: Pipe) -> Vector2i:
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == piece:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _global_to_grid(global_pos: Vector2) -> Vector2i:
	var x = round((global_pos.x - offset_x) / cell_size)
	var y = round((global_pos.y - offset_y) / cell_size)
	return Vector2i(x, y)

func _place_piece_at(piece: Pipe, grid_pos: Vector2i) -> void:
	if piece.get_parent() != self:
		var root = get_tree().current_scene
		root.remove_child(piece)
		add_child(piece)
	
	piece.position = Vector2(grid_pos.x * cell_size + offset_x, grid_pos.y * cell_size + offset_y)
	piece.z_index = 0
	grid[grid_pos.y][grid_pos.x] = piece
	
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

func _spawn_fixed_pipe(piece_type: int, grid_x: int, grid_y: int) -> Pipe:
	var new_pipe = pipe_scene_loaded.instantiate()
	add_child(new_pipe)
	
	# Calcula a posição exata baseada nas coordenadas x e y da matriz
	new_pipe.is_fixed = true
	
	new_pipe.position = Vector2(grid_x * cell_size + offset_x + (cell_size / 2.0), 
								grid_y * cell_size + offset_y + (cell_size / 2.0))

	new_pipe.type = piece_type
	new_pipe.scale = pipe_scale
	
	if piece_type in [1, 2]:
		new_pipe.visible = true
	
	var texture = _get_texture_for_type(piece_type)
	var base_connections = _get_base_connections(piece_type)
	new_pipe.set_pipe_data(texture, base_connections)
	
	return new_pipe
