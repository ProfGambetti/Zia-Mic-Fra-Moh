extends Node

@export var key_scene: PackedScene
@export var min_distance_from_player: float = 350.0

@onready var tilemap: TileMap = $TileMap
@onready var player: Node2D = $Player

var key_instance: Node2D
var walkable_cells: Array[Vector2i] = []

# ================= SPAWN ZOMBIE =================
@export var zombie_scene: PackedScene = preload("res://Scenes/zombie_enemy.tscn")
@export var zombie_spawn_interval_sec: float = 60.0
@export var zombies_per_wave: int = 5
@export var min_distance_from_player_for_zombie: float = 350.0
@export var min_distance_between_zombies: float = 100.0

var wave_count: int = 0

# Limiti mappa (calcolati automaticamente)
var map_min_pos: Vector2 = Vector2.INF
var map_max_pos: Vector2 = Vector2(-INF, -INF)
var map_margin_from_border: float = 32.0  # margine dai bordi mappa (in pixel)
# ================================================

func _ready() -> void:
	# ====================== TUTORIAL INIZIALE ======================
	var tutorial_scene = preload("res://tutorial.tscn")
	var tutorial = tutorial_scene.instantiate()
	add_child(tutorial)
	get_tree().paused = true
	
	tutorial.start_game.connect(_on_tutorial_start_game)
	# ============================================================
	
	if not key_scene:
		push_error("Key scene non assegnata nell'Inspector!")
		return
	
	walkable_cells = _get_walkable_cells()
	if walkable_cells.is_empty():
		push_error("Nessuna cella walkable trovata! Controlla Custom Data Layer 'walkable'")
		return
	
	# Calcola bounding box reale della mappa (rispetta dimensioni visibili)
	for cell in walkable_cells:
		var pos = tilemap.map_to_local(cell)
		map_min_pos.x = min(map_min_pos.x, pos.x)
		map_min_pos.y = min(map_min_pos.y, pos.y)
		map_max_pos.x = max(map_max_pos.x, pos.x)
		map_max_pos.y = max(map_max_pos.y, pos.y)
	
	# Applica margine interno per non spawnare proprio sui bordi
	map_min_pos += Vector2(map_margin_from_border, map_margin_from_border)
	map_max_pos -= Vector2(map_margin_from_border, map_margin_from_border)
	
	print("Mappa limiti calcolati: min ", map_min_pos, " - max ", map_max_pos)
	
	# Spawna la chiave (con controllo limiti)
	_spawn_key()
	
	# ================== SETUP TIMER ZOMBIE ==================
	var zombie_timer = Timer.new()
	zombie_timer.name = "ZombieSpawnTimer"
	zombie_timer.wait_time = zombie_spawn_interval_sec
	zombie_timer.one_shot = false
	zombie_timer.autostart = false
	zombie_timer.timeout.connect(_on_zombie_spawn_wave)
	add_child(zombie_timer)
	# ========================================================


func _on_tutorial_start_game() -> void:
	get_tree().paused = false
	print("Tutorial terminato - gioco avviato!")
	
	var zombie_timer = get_node_or_null("ZombieSpawnTimer")
	if zombie_timer:
		zombie_timer.start()
		print("Timer zombie avviato - prima ondata tra ", zombie_spawn_interval_sec, " secondi")


# ================== FUNZIONI ORIGINALI ==================
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
	for i in 100:
		var random_index = rng.randi_range(0, walkable_cells.size() - 1)
		var cell = walkable_cells[random_index]
		var pos = tilemap.map_to_local(cell)
		
		# Controllo limiti mappa + margine
		if pos.x < map_min_pos.x or pos.x > map_max_pos.x or \
		   pos.y < map_min_pos.y or pos.y > map_max_pos.y:
			continue
		
		if pos.distance_to(player.global_position) >= min_distance_from_player:
			key_instance = key_scene.instantiate()
			key_instance.global_position = pos
			add_child(key_instance)
			print("Chiave spawnata in: ", pos, " (entro limiti mappa)")
			return
	
	push_warning("Impossibile trovare posizione valida per la chiave dopo 100 tentativi")


# ================== ONDE ZOMBIE ==================
func _on_zombie_spawn_wave() -> void:
	wave_count += 1
	
	print("=== Ondata zombie #" + str(wave_count) + " iniziata === (" + str(zombies_per_wave) + " zombie)")
	
	for wave_index in zombies_per_wave:
		_try_spawn_single_zombie()
		
		if wave_index < zombies_per_wave - 1:
			await get_tree().create_timer(0.08).timeout
	
	print("Ondata #" + str(wave_count) + " completata")


func _try_spawn_single_zombie() -> void:
	if walkable_cells.is_empty():
		push_warning("Nessuna cella walkable disponibile per zombie")
		return
	
	var attempts = 0
	const MAX_ATTEMPTS = 60
	
	while attempts < MAX_ATTEMPTS:
		attempts += 1
		
		var random_index = randi() % walkable_cells.size()
		var cell = walkable_cells[random_index]
		var pos = tilemap.map_to_local(cell)
		
		# Controllo limiti mappa + margine (rispetta 1152×648 circa)
		if pos.x < map_min_pos.x or pos.x > map_max_pos.x or \
		   pos.y < map_min_pos.y or pos.y > map_max_pos.y:
			continue
		
		if pos.distance_to(player.global_position) < min_distance_from_player_for_zombie:
			continue
		
		var too_close = false
		for child in get_children():
			if child is Zombie:
				if pos.distance_to(child.global_position) < min_distance_between_zombies:
					too_close = true
					break
		if too_close:
			continue
		
		var zombie = zombie_scene.instantiate() as Node2D
		zombie.global_position = pos
		add_child(zombie)
		print("Zombie spawnato in ondata #" + str(wave_count) + " → cell ", cell, " pos ", pos)
		return
	
	push_warning("Impossibile trovare posizione valida per zombie dopo %d tentativi" % MAX_ATTEMPTS)
