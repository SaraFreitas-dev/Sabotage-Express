extends Node2D # Ou Node3D, depende do seu projeto

func _ready() -> void:
	# Pequeno atraso para garantir que todos os nós filhos (Tiles_grid, Main, etc)
	# foram instanciados na árvore antes do level_manager tentar buscá-los.
	await get_tree().process_frame
	
	# Chama o manager para iniciar as configurações com o nível desejado
	# Você pode pegar o número do nível de uma variável global ou passar fixo aqui
	LevelManager.start_level(1)
