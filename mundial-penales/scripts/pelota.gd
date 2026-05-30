extends Area2D

var velocidad = Vector2.ZERO
var velocidad_z = 0.0
var altura = 0.0
var gravedad = 600.0
var en_movimiento = false
var ya_revisado = false
var golpeo_palo = false
var fue_atajada = false

var palo_izq = 330.5
var palo_der = 820.5
var linea_de_gol = 337.0
var alto_travesano = 120.0

var escala_max = 1.0
var escala_min = 0.65
var pos_y_inicio = 0.0
var pos_original: Vector2
var padre_original: Node

@onready var anim = $AnimatedSprite2D
@onready var col = $CollisionShape2D


func _ready():
	anim.play("idle")
	pos_original = global_position
	padre_original = get_parent()


func patear(fuerza: Vector2, fuerza_z: float):
	en_movimiento = true
	velocidad = fuerza
	velocidad_z = fuerza_z
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	pos_y_inicio = global_position.y
	anim.play("remate")
	col.set_deferred("disabled", true)
	if Global.ia and Global.turno_jugador:
		var arq = get_node_or_null("/root/Cancha/arquero")
		if arq and arq.has_method("reaccionar_ia"):
			arq.reaccionar_ia()
	_reiniciar_despues()


func _process(dt):
	if not en_movimiento:
		return
	var vz_ant = velocidad_z
	velocidad_z -= gravedad * dt
	altura += ((vz_ant + velocidad_z) / 2.0) * dt
	global_position += velocidad * dt
	if col.disabled and global_position.y < linea_de_gol + 250 and not fue_atajada:
		col.set_deferred("disabled", false)
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
				anim.play("idle")
	anim.position.y = -altura
	if pos_y_inicio != 0:
		var progreso = clamp(1.0 - (global_position.y - linea_de_gol) / (pos_y_inicio - linea_de_gol), 0.0, 1.0)
		var esc = lerp(escala_max, escala_min, progreso)
		anim.scale = Vector2(esc, esc) * Vector2(0.4, 0.4)
	if not ya_revisado:
		_ver_atajada()
		_ver_palos()
		_ver_gol()


func _ver_atajada():
	if fue_atajada:
		return
	var arq = get_node_or_null("/root/Cancha/arquero")
	if not arq or not arq.esta_ocupado:
		return
	if global_position.y > linea_de_gol + 80:
		return
	var centro_arq = arq.posicion_inicial.x + arq.colision.position.x
	var dir_h = arq.direccion_horizontal_actual
	var px = global_position.x
	var en_zona = false
	if dir_h == -1:
		en_zona = px < centro_arq + 40.0
	elif dir_h == 1:
		en_zona = px > centro_arq - 40.0
	else:
		en_zona = abs(px - centro_arq) < 100.0
	if en_zona and arq.altura_compatible(altura):
		fue_atajada = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.5
		velocidad.y = abs(velocidad.y) * 0.6
		velocidad_z *= 0.3
		col.set_deferred("disabled", true)


func _ver_palos():
	if global_position.y > linea_de_gol or global_position.y < linea_de_gol - 100:
		return
	if altura > alto_travesano:
		return
	var margen = 18.0
	var px = global_position.x
	var pego_izq = abs(px - palo_izq) < margen and px <= palo_izq + margen
	var pego_der = abs(px - palo_der) < margen and px >= palo_der - margen
	if pego_izq or pego_der:
		golpeo_palo = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.6
		velocidad.y = abs(velocidad.y) * 0.5
		velocidad_z *= 0.5


func _ver_gol():
	if global_position.y > linea_de_gol or fue_atajada:
		return
	ya_revisado = true
	var px = global_position.x
	var dentro = px > palo_izq and px < palo_der
	var bajo = altura < alto_travesano
	if dentro and bajo:
		velocidad *= 0.15
		velocidad_z *= 0.3
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
	if padre_original:
		reparent(padre_original)
	en_movimiento = false
	velocidad = Vector2.ZERO
	velocidad_z = 0.0
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	global_position = pos_original
	anim.position.y = 0
	anim.scale = Vector2(0.4, 0.4)
	anim.play("idle")
	col.set_deferred("disabled", false)
	Global.penales_pateados += 1
	if _chequear_fin():
		return
	if Global.ia:
		Global.turno_jugador = not Global.turno_jugador
		if not Global.turno_jugador:
			await get_tree().create_timer(1.0).timeout
			var jug = get_node_or_null("/root/Cancha/Jugador")
			if jug and jug.has_method("patear_ia"):
				jug.patear_ia()


func _chequear_fin() -> bool:
	var mitad = Global.max_penales
	var pateados = Global.penales_pateados
	if pateados >= mitad * 2:
		if Global.goles_jugador != Global.goles_rival:
			_fin_partido()
			return true
		else:
			Global.max_penales += 1
			return false
	var rest_jug = mitad - ceili(pateados / 2.0)
	var rest_riv = mitad - (pateados / 2)
	if Global.goles_jugador > Global.goles_rival + rest_riv:
		_fin_partido()
		return true
	if Global.goles_rival > Global.goles_jugador + rest_jug:
		_fin_partido()
		return true
	return false


func _fin_partido():
	await get_tree().create_timer(1.5).timeout
	if Global.torneo_activo:
		if Global.goles_jugador > Global.goles_rival:
			if Global.ronda == "final":
				get_tree().change_scene_to_file("res://escenas/campeon.tscn")
			else:
				Global.avanzar_ronda()
				get_tree().change_scene_to_file("res://escenas/torneo.tscn")
		else:
			get_tree().change_scene_to_file("res://escenas/derrota.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/derrota.tscn")
