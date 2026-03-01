extends Node

@export var key_scene: PackedScene 
@export var min_distance_from_player: float = 350.0

@onready var tilemap: TileMap = $TileMap  
@onready var player: Node2D = $Player                

var key_instance: Node2D
var walkable_cells: Array[Vector2i] = []


func _ready() -> void:
	if not key_scene:
		push_error("Key scene non assegnata nell'Inspector!")
		return
	
	# 1. Raccogliamo una volta sola tutte le celle camminabili
	walkable_cells = _get_walkable_cells()
	
	if walkable_cells.is_empty():
		push_error("Nessuna cella walkable trovata! Controlla Custom Data Layer 'walkable'")
		return
	
	# 2. Spawniamo la chiave
	_spawn_key()


func _get_walkable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells(0)
	
	for cell_coord in used_cells:
		var tile_data: TileData = tilemap.get_cell_tile_data(0, cell_coord)
		if tile_data and tile_data.get_custom_data("walkable") == true:
			cells.append(cell_coord)
	
	return cells


func _spawn_key() -> void:
	var rng = RandomNumberGenerator.new()
	
	# Proviamo fino a 100 volte (dovrebbe bastarne pochissime)
	for i in 100:
		var random_index = rng.randi_range(0, walkable_cells.size() - 1)
		var cell = walkable_cells[random_index]
		
		# Posizione globale al centro della cella
		var pos = tilemap.map_to_local(cell)
		# Se vuoi esattamente al centro del tile:
		# pos += tilemap.tile_set.tile_size / 2.0   ← decommenta se serve
		
		# Controllo distanza minima dal player
		if pos.distance_to(player.global_position) >= min_distance_from_player:
			key_instance = key_scene.instantiate()
			key_instance.global_position = pos
			add_child(key_instance)
			
			print("Chiave spawnata in: ", pos)
			return
	
	push_warning("Impossibile trovare posizione valida per la chiave dopo 100 tentativi")
