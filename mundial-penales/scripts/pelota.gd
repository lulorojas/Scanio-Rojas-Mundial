extends Area2D

var velocidad = Vector2.ZERO
var velocidad_z = 0.0
var altura = 0.0
var gravedad = 600.0
var en_movimiento = false
var ya_revisado = false
var golpeo_palo = false
var fue_atajada = false
var fue_gol = false

var palo_izquierdo = 330.5
var palo_derecho = 820.5
var linea_de_gol = 337.0
var alto_travesano = 120.0

var escala_maxima = 1.0
var escala_minima = 0.65
var posicion_y_inicio = 0.0
var posicion_original: Vector2
var padre_original: Node

@onready var animacion = $AnimatedSprite2D
@onready var colision = $CollisionShape2D


func _ready():
	animacion.play("idle")
	posicion_original = global_position
	padre_original = get_parent()


func patear(fuerza: Vector2, fuerza_z: float):
	en_movimiento = true
	velocidad = fuerza
	velocidad_z = fuerza_z
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	fue_gol = false
	posicion_y_inicio = global_position.y
	animacion.play("remate")
	colision.set_deferred("disabled", true)
	if Global.ia and Global.turno_jugador:
		var arquero = get_node_or_null("/root/Cancha/arquero")
		if arquero and arquero.has_method("reaccionar_ia"):
			arquero.reaccionar_ia()
	_reiniciar_despues()


func _process(delta):
	if not en_movimiento:
		return
	var velocidad_z_anterior = velocidad_z
	velocidad_z -= gravedad * delta
	altura += ((velocidad_z_anterior + velocidad_z) / 2.0) * delta
	global_position += velocidad * delta
	if colision.disabled and global_position.y < linea_de_gol + 250 and not fue_atajada:
		colision.set_deferred("disabled", false)
	if altura <= 0:
		altura = 0
		if abs(velocidad_z) > 80:
			velocidad_z = -velocidad_z * 0.3
			velocidad *= 0.7
		else:
			velocidad_z = 0
			velocidad *= 0.92
			if velocidad.length() < 10.0:
				velocidad = Vector2.ZERO
				en_movimiento = false
				animacion.play("idle")
	animacion.position.y = -altura
	if posicion_y_inicio != 0:
		var progreso = clamp(1.0 - (global_position.y - linea_de_gol) / (posicion_y_inicio - linea_de_gol), 0.0, 1.0)
		var escala = lerp(escala_maxima, escala_minima, progreso)
		animacion.scale = Vector2(escala, escala) * Vector2(0.4, 0.4)
	if not ya_revisado:
		_verificar_atajada()
		_verificar_palos()
		_verificar_gol()


func _verificar_atajada():
	if fue_atajada:
		return
	var arquero = get_node_or_null("/root/Cancha/arquero")
	if not arquero or not arquero.esta_ocupado:
		return
	if global_position.y > linea_de_gol + 80:
		return
	var centro_arquero = arquero.posicion_inicial.x + arquero.colision.position.x
	var direccion_horizontal = arquero.direccion_horizontal_actual
	var posicion_x = global_position.x
	var en_zona = false
	if direccion_horizontal == -1:
		en_zona = posicion_x < centro_arquero + 40.0
	elif direccion_horizontal == 1:
		en_zona = posicion_x > centro_arquero - 40.0
	else:
		en_zona = abs(posicion_x - centro_arquero) < 100.0
	if en_zona and arquero.altura_compatible(altura):
		fue_atajada = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.5
		velocidad.y = abs(velocidad.y) * 0.6
		velocidad_z *= 0.3
		colision.set_deferred("disabled", true)


func _verificar_palos():
	if global_position.y > linea_de_gol or global_position.y < linea_de_gol - 100:
		return
	if altura > alto_travesano:
		return
	var margen = 18.0
	var posicion_x = global_position.x
	var pego_izquierdo = abs(posicion_x - palo_izquierdo) < margen and posicion_x <= palo_izquierdo + margen
	var pego_derecho = abs(posicion_x - palo_derecho) < margen and posicion_x >= palo_derecho - margen
	if pego_izquierdo or pego_derecho:
		golpeo_palo = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.6
		velocidad.y = abs(velocidad.y) * 0.5
		velocidad_z *= 0.5


func _verificar_gol():
	if global_position.y > linea_de_gol or fue_atajada:
		return
	ya_revisado = true
	var posicion_x = global_position.x
	var dentro = posicion_x > palo_izquierdo and posicion_x < palo_derecho
	var bajo = altura < alto_travesano
	if dentro and bajo:
		velocidad *= 0.15
		velocidad_z *= 0.3
		fue_gol = true
		if Global.turno_jugador:
			Global.goles_jugador += 1
		else:
			Global.goles_rival += 1
	elif not bajo and dentro:
		if abs(altura - alto_travesano) < 15.0:
			velocidad_z = -velocidad_z * 0.4
			velocidad.y = -velocidad.y * 0.5
	elif not dentro:
		velocidad *= 0.5


func _reiniciar_despues():
	await get_tree().create_timer(5.0).timeout
	if Global.turno_jugador:
		Global.resultados_jugador.append(fue_gol)
	else:
		Global.resultados_rival.append(fue_gol)
	if padre_original:
		reparent(padre_original)
	en_movimiento = false
	velocidad = Vector2.ZERO
	velocidad_z = 0.0
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	fue_gol = false
	global_position = posicion_original
	animacion.position.y = 0
	animacion.scale = Vector2(0.4, 0.4)
	animacion.play("idle")
	colision.set_deferred("disabled", false)
	var jugador = get_node_or_null("/root/Cancha/Jugador")
	if not Global.turno_jugador and jugador:
		var ruta_equipo = "res://assets/animaciones/" + Global.equipo + ".tres"
		var recurso_equipo = load(ruta_equipo)
		if recurso_equipo:
			jugador.animacion.sprite_frames = recurso_equipo
		jugador.animacion.play("idle")
	Global.penales_pateados += 1
	if _chequear_fin():
		return
	if Global.ia:
		Global.turno_jugador = not Global.turno_jugador
		if not Global.turno_jugador:
			if jugador:
				var ruta_rival = "res://assets/animaciones/" + Global.rival_actual + ".tres"
				var recurso_rival = load(ruta_rival)
				if recurso_rival:
					jugador.animacion.sprite_frames = recurso_rival
				jugador.animacion.play("idle")
			await get_tree().create_timer(2.0).timeout
			if jugador and jugador.has_method("patear_ia"):
				jugador.patear_ia()


func _chequear_fin() -> bool:
	var pateados = Global.penales_pateados
	var maximo = Global.maximo_penales
	if maximo == 5:
		if pateados >= 10:
			if Global.goles_jugador != Global.goles_rival:
				_fin_partido()
				return true
			else:
				Global.maximo_penales = 6
				Global.resultados_jugador = []
				Global.resultados_rival = []
				return false
		var pateados_jugador = ceili(pateados / 2.0)
		var pateados_rival = pateados / 2
		var restantes_jugador = 5 - pateados_jugador
		var restantes_rival = 5 - pateados_rival
		if Global.goles_jugador > Global.goles_rival + restantes_rival:
			_fin_partido()
			return true
		if Global.goles_rival > Global.goles_jugador + restantes_jugador:
			_fin_partido()
			return true
		return false
	else:
		var penales_muerte_subita = pateados - 10
		if penales_muerte_subita > 0 and penales_muerte_subita % 2 == 0:
			if Global.goles_jugador != Global.goles_rival:
				_fin_partido()
				return true
			else:
				Global.resultados_jugador = []
				Global.resultados_rival = []
		return false


func _fin_partido():
	await get_tree().create_timer(1.5).timeout
	if Global.torneo_activo:
		if Global.goles_jugador > Global.goles_rival:
			if Global.ronda == "final":
				Global.avanzar_ronda()
				get_tree().change_scene_to_file("res://escenas/campeon.tscn")
			else:
				Global.avanzar_ronda()
				get_tree().change_scene_to_file("res://escenas/fases.tscn")
		else:
			get_tree().change_scene_to_file("res://escenas/derrota.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/derrota.tscn")
