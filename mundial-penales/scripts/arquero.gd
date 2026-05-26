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
