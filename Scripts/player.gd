extends CharacterBody2D
class_name Player

@onready var health_system = $HealthSystem as HealthSystem
@onready var shooting_system = $ShootingSystem as ShootingSystem
@onready var shot_stream_player = $Sounds/ShotStreamPlayer
@onready var reload_stream_player = $Sounds/ReloadStreamPlayer

@export var damage_per_bullet = 5
@export var player_ui: PlayerUI
@export var speed: float = 300.0
@export var rotation_speed: float = 10.0 # Aumentato per rotazione più reattiva (prova 8-15)
@export var acceleration: float = 2000.0 # Nuova: accelerazione/decel. Realistica (prova 1500-3000)

var has_key = false

func _ready():
	player_ui.set_life_bar_max_value(health_system.base_health)
	player_ui.set_max_ammo(shooting_system.magazine_size)
	player_ui.set_ammo_left(shooting_system.max_ammo)
	shooting_system.shot.connect(on_shot)
	shooting_system.gun_reload.connect(on_reload)
	shooting_system.ammo_added.connect(on_ammo_added)
	health_system.died.connect(on_died)
	
	# Reset velocity iniziale per sicurezza
	velocity = Vector2.ZERO

func _physics_process(delta):
	# Input vettoriale grezzo
	var raw_input_dir = Input.get_vector(
		"move_left", # neg_x: A (strafe left)
		"move_right", # pos_x: D (strafe right)
		"move_forward", # neg_y: W (forward)
		"move_backwards" # pos_y: S (backward)
	)
	
	# DEADZONE per eliminare drift da joypad/controller noise (comune causa!)
	var input_dir = Vector2.ZERO
	if raw_input_dir.length() > 0.1:
		input_dir = raw_input_dir.normalized()
	
	# Movimento RELATIVO alla rotazione (tank-like: W=forward, S=back, A/D=strafe)
	var forward_amount = -input_dir.y  # W → +forward, S → -forward (back)
	var strafe_amount = input_dir.x    # D → +strafe right, A → -strafe left
	var target_velocity = (transform.x * forward_amount + transform.y * strafe_amount) * speed
	
	# Accelerazione/decelerazione fluida (realistica!)
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	move_and_slide()
	
	# Rotazione fluida verso mouse (indipendente dal movimento)
	var target_angle = (get_global_mouse_position() - global_position).angle()
	global_rotation = lerp_angle(global_rotation, target_angle, delta * rotation_speed)

func take_damage(damage: int):
	health_system.take_damage(damage)
	player_ui.update_life_bar_value(health_system.current_health)

func on_shot(ammo_in_magazine: int):
	shot_stream_player.play()
	player_ui.bullet_shot(ammo_in_magazine)

func on_reload(ammo_in_magazine: int, ammo_left: int):
	reload_stream_player.play()
	player_ui.gun_reloaded(ammo_in_magazine, ammo_left)

func on_ammo_pickup():
	shooting_system.on_ammo_pickup()

func on_ammo_added(total_ammo: int):
	player_ui.set_ammo_left(total_ammo)

func on_health_pickup(health_to_restore: int):
	health_system.current_health += health_to_restore
	player_ui.life_bar.value += health_to_restore

func on_key_pickup():
	has_key = true
	player_ui.on_key_pickup()

func update_extract_timer(time_left: float):
	player_ui.update_extract_timer(time_left)

func hide_extract_countdown():
	player_ui.hide_extract_countdown()

func extract():
	player_ui.on_game_over(false)
	queue_free()

func on_died():
	player_ui.on_game_over(true)
	queue_free()
