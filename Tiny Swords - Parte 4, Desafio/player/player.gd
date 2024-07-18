class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 1
@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene
@export_category("Life")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0
var attack_count: int = 1


signal meat_collected(value: int)


func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int):
		GameManager.meat_counter += 1
	)


func _process(delta: float) -> void:
	GameManager.player_position = position
	
	# Ler input
	read_input()

	# Processar ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack(input_vector)
	
	# Processar animação e rotação de sprite
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()
	
	# Processar dano
	update_hitbox_detection(delta)
	
	# Ritual
	update_ritual(delta)
	
	# Atualizar health bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health


func _physics_process(delta: float) -> void:
	# Modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()


func update_attack_cooldown(delta: float) -> void:
	# Atualizar temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")


func update_ritual(delta: float) -> void:
	# Atualizar temporizador
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	ritual_cooldown = ritual_interval
	
	# Criar ritual
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)


func read_input() -> void:
	# Obter o input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Apagar deadzone do input vector
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
	# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()


func play_run_idle_animation() -> void:
	# Tocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")


func rotate_sprite() -> void:
	# Girar sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true


func attack(input_vector: Vector2) -> void:
	if is_attacking:
		return
	#Checa se o Y é maior ou menor que o X
	var module_y: float
	if input_vector.y < 0:
		module_y = input_vector.y * (-1)
	else:
		module_y = input_vector.y
	var module_x: float
	if input_vector.x < 0:
		module_x = input_vector.x * (-1)
	else:
		module_x = input_vector.x
	
	var attack_direction
	#Calculo do x ou y
	if module_y > module_x:
		attack_direction = "Y"
	else:
		attack_direction = "X"
	
	# Escolhe animação
	var even = attack_count % 2
	
	#Toca animação
	
	if attack_direction == "Y" && input_vector.y < 0:
		if even == 0:
			animation_player.play("attack_up_1")
			attack_count += 1
		else:
			animation_player.play("attack_up_2")
			attack_count += 1
	elif attack_direction == "Y":
		if even == 0:
			animation_player.play("attack_down_1")
			attack_count +=1
		else:
			animation_player.play("attack_down_2")
			attack_count +=1
	else:
		if even == 0:
			animation_player.play("attack_side_1")
			attack_count += 1
		else:
			animation_player.play("attack_side_2")
			attack_count += 1
	
	# Configurar temporizador
	attack_cooldown = 0.6
	
	# Marcar ataque
	is_attacking = true


func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			
			#Checa se o Y é maior ou menor que o X
			var module_y: float
			if input_vector.y < 0:
				module_y = input_vector.y * (-1)
			else:
				module_y = input_vector.y
			var module_x: float
			if input_vector.x < 0:
				module_x = input_vector.x * (-1)
			else:
				module_x = input_vector.x
			
			var attack_direction_angle
			#Calculo do x ou y
			if module_y > module_x:
				attack_direction_angle = "Y"
			else:
				attack_direction_angle = "X"
			
			if attack_direction_angle == "X":
				if sprite.flip_h:
					attack_direction = Vector2.LEFT
				else:
					attack_direction = Vector2.RIGHT
			else:
				if input_vector.y > 0:
					attack_direction = Vector2.DOWN
				else:
					attack_direction = Vector2.UP
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product >= 0.3:
				enemy.damage(sword_damage)


func update_hitbox_detection(delta: float) -> void:
	# Temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	# Frequência
	hitbox_cooldown = 0.5
	
	# Detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)


func damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health, "/", max_health)
	
	# Piscar node
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	
	# Processar morte
	if health <= 0:
		die()


func die() -> void:
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	print("Player morreu!")
	attack_count = 0
	queue_free()



func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu cura de ", amount, ". A vida total é de ", health, "/", max_health)
	return health




