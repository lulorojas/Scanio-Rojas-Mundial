extends Area2D

@export var distancia_horizontal = 220.0
@export var distancia_vertical = 120.0
@export var tiempo_vuelo = 0.3
@export var tiempo_suelo = 0.6
@export var grados_inclinacion = 75.0

var posicion_inicial: Vector2
var esta_ocupado = false
var tiempo_reaccion = 0.25
var delta_simulacion = 0.016
var maximo_pasos = 200
var direccion_vertical_actual = 0
var direccion_horizontal_actual = 0
var probabilidad_error = {
	"octavos": 0.95,
	"cuartos": 0.65,
	"semis": 0.55,
	"final": 0.38
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

	var dir_h = 0.0
	var dir_v = 0.0
	var intenta = false

	if Input.is_key_pressed(KEY_Q):
		dir_h = -1.0
		dir_v = -1.0
		intenta = true
	elif Input.is_key_pressed(KEY_E):
		dir_h = 1.0
		dir_v = -1.0
		intenta = true
	elif Input.is_key_pressed(KEY_A):
		dir_h = -1.0
		dir_v = 0.0
		intenta = true
	elif Input.is_key_pressed(KEY_D):
		dir_h = 1.0
		dir_v = 0.0
		intenta = true
	elif Input.is_key_pressed(KEY_Z):
		dir_h = -1.0
		dir_v = 1.0
		intenta = true
	elif Input.is_key_pressed(KEY_C):
		dir_h = 1.0
		dir_v = 1.0
		intenta = true
	elif Input.is_key_pressed(KEY_W):
		dir_h = 0.0
		dir_v = -1.0
		intenta = true
	elif Input.is_key_pressed(KEY_S):
		dir_h = 0.0
		dir_v = 0.0
		intenta = true

	if intenta:
		_lanzar_arquero(dir_h, dir_v)


func _lanzar_arquero(dir_h: float, dir_v: float):
	esta_ocupado = true
	direccion_vertical_actual = int(dir_v)
	direccion_horizontal_actual = int(dir_h)
	var destino = posicion_inicial + Vector2(dir_h * distancia_horizontal, dir_v * distancia_vertical)

	if dir_h < 0:
		animacion.flip_h = false
	elif dir_h > 0:
		animacion.flip_h = true
	else:
		animacion.flip_h = false
	animacion.play("atajar")

	var angulo = dir_h * grados_inclinacion
	var tween = create_tween()

	tween.tween_property(self, "global_position", destino, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(animacion, "rotation_degrees", angulo, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(colision, "rotation_degrees", angulo, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_interval(tiempo_suelo)

	tween.tween_property(self, "global_position", posicion_inicial, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(animacion, "rotation_degrees", 0.0, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(colision, "rotation_degrees", 0.0, tiempo_vuelo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(_finalizar_atajada)


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
	var nodo = get_node_or_null("/root/Cancha/Jugador/Pelota")
	if nodo: return nodo
	nodo = get_node_or_null("/root/Cancha/Pelota")
	if nodo: return nodo
	nodo = get_node_or_null("/root/Cancha/pelota")
	if nodo: return nodo
	return _buscar_en_hijos(get_tree().current_scene)


func _buscar_en_hijos(nodo_actual: Node) -> Node:
	for hijo in nodo_actual.get_children():
		if "velocidad" in hijo and "velocidad_z" in hijo and "linea_de_gol" in hijo and "altura" in hijo:
			return hijo
		var resultado = _buscar_en_hijos(hijo)
		if resultado: return resultado
	return null


func _simular_trayectoria(pelota: Node) -> Dictionary:
	var sim_pos = pelota.global_position
	var sim_vel = pelota.velocidad
	var sim_vz = pelota.velocidad_z
	var sim_alt = pelota.altura
	var grav = pelota.gravedad
	var linea = pelota.linea_de_gol

	for i in range(maximo_pasos):
		var vz_ant = sim_vz
		sim_vz -= grav * delta_simulacion
		sim_alt += ((vz_ant + sim_vz) / 2.0) * delta_simulacion
		sim_pos += sim_vel * delta_simulacion

		if sim_alt <= 0.0:
			sim_alt = 0.0
			if abs(sim_vz) > 80.0:
				sim_vz = -sim_vz * 0.3
				sim_vel *= 0.7
			else:
				sim_vz = 0.0
				sim_vel *= 0.92

		if sim_pos.y <= linea:
			return {"pos_x": sim_pos.x, "altura": sim_alt, "llego": true}

		if sim_vel.length() < 5.0 and sim_vz == 0.0:
			break

	return {"pos_x": sim_pos.x, "altura": sim_alt, "llego": false}


func _elegir_direccion(pelota: Node) -> Array:
	var resultado = _simular_trayectoria(pelota)
	if not resultado["llego"]:
		return [0, 0]

	var pos_x = resultado["pos_x"]
	var alt = resultado["altura"]
	var centro = posicion_inicial.x + colision.position.x

	var dif_x = pos_x - centro
	var dir_h = 0
	var dir_v = 0

	if dif_x < -25.0:
		dir_h = -1
	elif dif_x > 25.0:
		dir_h = 1

	if alt > 75.0:
		dir_v = -1
	elif alt < 25.0:
		dir_v = 1

	return [dir_h, dir_v]


func reaccionar_ia():
	var delay = randf_range(0.0, 0.15)
	await get_tree().create_timer(tiempo_reaccion + delay).timeout

	var pelota = _buscar_pelota()
	var dir_h = 0
	var dir_v = 0

	if pelota and pelota.en_movimiento:
		var decision = _elegir_direccion(pelota)
		var dir_correcta_h = decision[0]
		var dir_correcta_v = decision[1]

		var prob = probabilidad_error.get(Global.ronda, 0.40)
		if randf() < prob:
			var opciones_h = [-1, 0, 1]
			opciones_h.erase(dir_correcta_h)
			dir_h = opciones_h[randi() % opciones_h.size()]
			var opciones_v = [-1, 0, 1]
			opciones_v.erase(dir_correcta_v)
			dir_v = opciones_v[randi() % opciones_v.size()]
		else:
			dir_h = dir_correcta_h
			dir_v = dir_correcta_v
	else:
		dir_h = randi_range(-1, 1)
		dir_v = randi_range(-1, 1)

	_lanzar_arquero(dir_h, dir_v)
