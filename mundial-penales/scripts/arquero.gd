extends Area2D

@export var distancia_horizontal: float = 220.0
@export var distancia_vertical: float = 120.0
@export var tiempo_de_vuelo: float = 0.3
@export var tiempo_en_suelo: float = 0.6
@export var grados_de_inclinacion: float = 75.0

var posicion_inicial: Vector2
var esta_ocupado: bool = false

@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready():
	posicion_inicial = global_position
	animacion.play("quieto")

func _process(_delta):
	if esta_ocupado:
		return
	if Global.contra_ia:
		return

	var direccion_horizontal: float = 0.0
	var direccion_vertical: float = 0.0
	var intenta_atajar: bool = false

	if Input.is_key_pressed(KEY_Q):
		direccion_horizontal = -1.0
		direccion_vertical = -1.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_E):
		direccion_horizontal = 1.0
		direccion_vertical = -1.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_A):
		direccion_horizontal = -1.0
		direccion_vertical = 0.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_D):
		direccion_horizontal = 1.0
		direccion_vertical = 0.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_Z):
		direccion_horizontal = -1.0
		direccion_vertical = 1.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_C):
		direccion_horizontal = 1.0
		direccion_vertical = 1.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_W):
		direccion_horizontal = 0.0
		direccion_vertical = -1.0
		intenta_atajar = true
	elif Input.is_key_pressed(KEY_S):
		direccion_horizontal = 0.0
		direccion_vertical = 0.0
		intenta_atajar = true

	if intenta_atajar:
		_lanzar_arquero(direccion_horizontal, direccion_vertical)

func _lanzar_arquero(direccion_horizontal: float, direccion_vertical: float):
	esta_ocupado = true
	var posicion_destino: Vector2 = posicion_inicial + Vector2(direccion_horizontal * distancia_horizontal, direccion_vertical * distancia_vertical)

	if direccion_horizontal < 0:
		animacion.flip_h = false
		animacion.play("atajar")
	elif direccion_horizontal > 0:
		animacion.flip_h = true
		animacion.play("atajar")
	else:
		animacion.flip_h = false
		animacion.play("atajar")

	var angulo_de_rotacion: float = direccion_horizontal * grados_de_inclinacion

	var manejador = create_tween()

	manejador.tween_property(self, "global_position", posicion_destino, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	manejador.parallel().tween_property(animacion, "rotation_degrees", angulo_de_rotacion, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	manejador.parallel().tween_property(colision, "rotation_degrees", angulo_de_rotacion, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	manejador.tween_interval(tiempo_en_suelo)

	manejador.tween_property(self, "global_position", posicion_inicial, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	manejador.parallel().tween_property(animacion, "rotation_degrees", 0.0, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	manejador.parallel().tween_property(colision, "rotation_degrees", 0.0, tiempo_de_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	manejador.finished.connect(_finalizar_atajada)

func _finalizar_atajada():
	animacion.play("quieto")
	animacion.flip_h = false
	animacion.rotation_degrees = 0.0
	colision.rotation_degrees = 0.0
	esta_ocupado = false

func reaccionar_ia() -> void:
	await get_tree().create_timer(0.05).timeout

	var pelota = get_node_or_null("/root/Cancha/Jugador/Pelota")
	if pelota == null:
		pelota = get_node_or_null("/root/Cancha/Pelota")
	if pelota == null:
		for hijo in get_tree().current_scene.get_children():
			if "vel" in hijo and "linea_gol" in hijo:
				pelota = hijo
				break

	var dir_x: int = 0
	var dir_y: int = 0

	if pelota and pelota.se_mueve:
		var centro_arco = posicion_inicial.x
		var vel_y_segura = pelota.vel.y
		if vel_y_segura == 0:
			vel_y_segura = -1.0 
			
		var distancia_y = pelota.linea_gol - pelota.global_position.y
		var tiempo_llegada = abs(distancia_y / vel_y_segura)
		tiempo_llegada = clamp(tiempo_llegada, 0.0, 1.5)
		
		var x_final = pelota.global_position.x + (pelota.vel.x * tiempo_llegada)
		var diferencia_x = x_final - centro_arco
		
		if diferencia_x < -45:
			dir_x = -1
		elif diferencia_x > 45:
			dir_x = 1
		else:
			dir_x = 0

		if pelota.vel_z > 140:
			dir_y = -1
		elif pelota.vel_z < 70:
			dir_y = 1
		else:
			dir_y = 0

		if randf() < 0.05:
			dir_x = randi_range(-1, 1)
			dir_y = randi_range(-1, 1)
	else:
		dir_x = randi_range(-1, 1)
		dir_y = randi_range(-1, 1)

	_lanzar_arquero(dir_x, dir_y)
