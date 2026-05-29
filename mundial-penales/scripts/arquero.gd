extends Area2D

@export var distancia_horizontal: float = 220.0
@export var distancia_vertical: float = 120.0
@export var tiempo_vuelo: float = 0.3
@export var tiempo_suelo: float = 0.6
@export var grados_inclinacion: float = 75.0

var posicion_inicial: Vector2
var esta_ocupado: bool = false
var tiempo_reaccion: float = 0.05
var delta_simulacion: float = 0.016
var maximo_pasos: int = 200
var direccion_vertical_actual: int = 0
var direccion_horizontal_actual: int = 0
var probabilidad_error: Dictionary = {
	"octavos": 0.35,
	"cuartos": 0.20,
	"semis": 0.10,
	"final": 0.03
}

@onready var animacion = $AnimatedSprite2D
@onready var colision = $CollisionShape2D

func _ready():
	posicion_inicial = global_position
	animacion.play("quieto")

func _process(_delta):
	if esta_ocupado:
		return
	if Global.ia and Global.turno_jugador:
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
	direccion_vertical_actual = int(direccion_vertical)
	direccion_horizontal_actual = int(direccion_horizontal)
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

	var angulo_rotacion: float = direccion_horizontal * grados_inclinacion

	var animador_atajada = create_tween()

	animador_atajada.tween_property(self, "global_position", posicion_destino, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animador_atajada.parallel().tween_property(animacion, "rotation_degrees", angulo_rotacion, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animador_atajada.parallel().tween_property(colision, "rotation_degrees", angulo_rotacion, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	animador_atajada.tween_interval(tiempo_suelo)

	animador_atajada.tween_property(self, "global_position", posicion_inicial, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	animador_atajada.parallel().tween_property(animacion, "rotation_degrees", 0.0, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	animador_atajada.parallel().tween_property(colision, "rotation_degrees", 0.0, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	animador_atajada.finished.connect(_finalizar_atajada)

func _finalizar_atajada():
	animacion.play("quieto")
	animacion.flip_h = false
	animacion.rotation_degrees = 0.0
	colision.rotation_degrees = 0.0
	esta_ocupado = false
	direccion_vertical_actual = 0
	direccion_horizontal_actual = 0

func altura_compatible(altura_pelota: float) -> bool:
	if direccion_vertical_actual == -1:
		return altura_pelota > 45.0
	elif direccion_vertical_actual == 1:
		return altura_pelota < 45.0
	else:
		return altura_pelota < 85.0

func _buscar_pelota() -> Node:
	var nodo_pelota = get_node_or_null("/root/Cancha/Jugador/Pelota")
	if nodo_pelota: return nodo_pelota
	nodo_pelota = get_node_or_null("/root/Cancha/Pelota")
	if nodo_pelota: return nodo_pelota
	nodo_pelota = get_node_or_null("/root/Cancha/pelota")
	if nodo_pelota: return nodo_pelota
	return _buscar_en_hijos(get_tree().current_scene)

func _buscar_en_hijos(nodo_actual: Node) -> Node:
	for hijo in nodo_actual.get_children():
		if "velocidad" in hijo and "velocidad_z" in hijo and "linea_gol" in hijo and "altura" in hijo:
			return hijo
		var resultado_busqueda = _buscar_en_hijos(hijo)
		if resultado_busqueda: return resultado_busqueda
	return null

func _simular_trayectoria(nodo_pelota: Node) -> Dictionary:
	var simulacion_posicion = nodo_pelota.global_position
	var simulacion_velocidad = nodo_pelota.velocidad
	var simulacion_velocidad_z = nodo_pelota.velocidad_z
	var simulacion_altura = nodo_pelota.altura
	var gravedad_pelota = nodo_pelota.gravedad
	var linea_meta = nodo_pelota.linea_gol
	var paso_tiempo = delta_simulacion

	for paso in range(maximo_pasos):
		var velocidad_z_anterior = simulacion_velocidad_z
		simulacion_velocidad_z -= gravedad_pelota * paso_tiempo
		simulacion_altura += ((velocidad_z_anterior + simulacion_velocidad_z) / 2.0) * paso_tiempo
		simulacion_posicion += simulacion_velocidad * paso_tiempo

		if simulacion_altura <= 0.0:
			simulacion_altura = 0.0
			if abs(simulacion_velocidad_z) > 80.0:
				simulacion_velocidad_z = -simulacion_velocidad_z * 0.3
				simulacion_velocidad *= 0.7
			else:
				simulacion_velocidad_z = 0.0
				simulacion_velocidad *= 0.92

		if simulacion_posicion.y <= linea_meta:
			return {"posicion_x": simulacion_posicion.x, "altura_final": simulacion_altura, "llego_al_arco": true}

		if simulacion_velocidad.length() < 5.0 and simulacion_velocidad_z == 0.0:
			break

	return {"posicion_x": simulacion_posicion.x, "altura_final": simulacion_altura, "llego_al_arco": false}

func _elegir_mejor_direccion(nodo_pelota: Node) -> Array:
	var resultado_simulacion = _simular_trayectoria(nodo_pelota)

	if not resultado_simulacion["llego_al_arco"]:
		return [0, 0]

	var posicion_x_final: float = resultado_simulacion["posicion_x"]
	var altura_final: float = resultado_simulacion["altura_final"]
	var centro_arco: float = posicion_inicial.x + colision.position.x

	var diferencia_x: float = posicion_x_final - centro_arco
	var direccion_horizontal: int = 0
	var direccion_vertical: int = 0

	if diferencia_x < -25.0:
		direccion_horizontal = -1
	elif diferencia_x > 25.0:
		direccion_horizontal = 1

	if altura_final > 75.0:
		direccion_vertical = -1
	elif altura_final < 25.0:
		direccion_vertical = 1

	return [direccion_horizontal, direccion_vertical]

func reaccionar_ia() -> void:
	await get_tree().create_timer(tiempo_reaccion).timeout

	var nodo_pelota = _buscar_pelota()

	var direccion_horizontal: int = 0
	var direccion_vertical: int = 0

	if nodo_pelota and nodo_pelota.moviendo:
		var probabilidad = probabilidad_error.get(Global.ronda, 0.20)
		if randf() < probabilidad:
			direccion_horizontal = randi_range(-1, 1)
			direccion_vertical = randi_range(-1, 1)
		else:
			var decision = _elegir_mejor_direccion(nodo_pelota)
			direccion_horizontal = decision[0]
			direccion_vertical = decision[1]
	else:
		direccion_horizontal = randi_range(-1, 1)
		direccion_vertical = randi_range(-1, 1)

	_lanzar_arquero(direccion_horizontal, direccion_vertical)
