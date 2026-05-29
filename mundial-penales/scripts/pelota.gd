
extends Area2D

var velocidad: Vector2 = Vector2.ZERO
var velocidad_z: float = 0.0
var altura: float = 0.0
var gravedad: float = 600.0
var en_movimiento: bool = false
var ya_revisado: bool = false
var golpeo_palo: bool = false
var fue_atajada: bool = false

var palo_izquierdo: float = 330.5
var palo_derecho: float = 820.5
var linea_de_gol: float = 337.0
var altura_travesano: float = 120.0

var escala_maxima: float = 1.0
var escala_minima: float = 0.65
var posicion_y_inicial: float = 0.0
var posicion_original: Vector2
var nodo_padre_original: Node

@onready var animacion = $AnimatedSprite2D
@onready var colision = $CollisionShape2D

func _ready():
	animacion.play("idle")
	posicion_original = global_position
	nodo_padre_original = get_parent()

func patear(fuerza_inicial: Vector2, fuerza_vertical: float):
	en_movimiento = true
	velocidad = fuerza_inicial
	velocidad_z = fuerza_vertical
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	posicion_y_inicial = global_position.y
	animacion.play("remate")
	colision.set_deferred("disabled", true)

	if Global.ia and Global.turno_jugador:
		var arquero = get_node_or_null("/root/Cancha/arquero")
		if arquero and arquero.has_method("reaccionar_ia"):
			arquero.reaccionar_ia()

	_reiniciar_despues_de_tiro()

func _process(delta_tiempo: float):
	if not en_movimiento:
		return

	var velocidad_z_anterior = velocidad_z
	velocidad_z -= gravedad * delta_tiempo
	altura += ((velocidad_z_anterior + velocidad_z) / 2.0) * delta_tiempo

	global_position += velocidad * delta_tiempo

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

	if posicion_y_inicial != 0:
		var progreso_vuelo = clamp(1.0 - (global_position.y - linea_de_gol) / (posicion_y_inicial - linea_de_gol), 0.0, 1.0)
		var escala_actual = lerp(escala_maxima, escala_minima, progreso_vuelo)
		animacion.scale = Vector2(escala_actual, escala_actual) * Vector2(0.4, 0.4)

	if not ya_revisado:
		_comprobar_atajada()
		_comprobar_palos()
		_comprobar_gol()

func _comprobar_atajada():
	if fue_atajada: 
		return
	var arquero = get_node_or_null("/root/Cancha/arquero")
	if not arquero or not arquero.esta_ocupado: 
		return
	if global_position.y > linea_de_gol + 80: 
		return
	
	var centro_arquero_x = arquero.posicion_inicial.x + arquero.colision.position.x
	var direccion_horizontal_arquero = arquero.direccion_horizontal_actual
	var posicion_pelota_x = global_position.x
	var esta_en_zona = false
	
	if direccion_horizontal_arquero == -1:
		esta_en_zona = posicion_pelota_x < centro_arquero_x + 40.0
	elif direccion_horizontal_arquero == 1:
		esta_en_zona = posicion_pelota_x > centro_arquero_x - 40.0
	else:
		esta_en_zona = abs(posicion_pelota_x - centro_arquero_x) < 100.0
		
	if esta_en_zona and arquero.altura_compatible(altura):
		fue_atajada = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.5
		velocidad.y = abs(velocidad.y) * 0.6
		velocidad_z *= 0.3
		colision.set_deferred("disabled", true)

func _comprobar_palos():
	if global_position.y > linea_de_gol or global_position.y < linea_de_gol - 100:
		return
	if altura > altura_travesano:
		return

	var margen_error = 18.0
	var posicion_pelota_x = global_position.x
	var choco_izquierdo = abs(posicion_pelota_x - palo_izquierdo) < margen_error and posicion_pelota_x <= palo_izquierdo + margen_error
	var choco_derecho = abs(posicion_pelota_x - palo_derecho) < margen_error and posicion_pelota_x >= palo_derecho - margen_error

	if choco_izquierdo or choco_derecho:
		golpeo_palo = true
		ya_revisado = true
		velocidad.x = -velocidad.x * 0.6
		velocidad.y = abs(velocidad.y) * 0.5
		velocidad_z *= 0.5

func _comprobar_gol():
	if global_position.y > linea_de_gol or fue_atajada:
		return

	ya_revisado = true

	var posicion_pelota_x = global_position.x
	var esta_dentro_arco = posicion_pelota_x > palo_izquierdo and posicion_pelota_x < palo_derecho
	var paso_bajo_travesano = altura < altura_travesano

	if esta_dentro_arco and paso_bajo_travesano:
		velocidad *= 0.15
		velocidad_z *= 0.3
	elif not paso_bajo_travesano and esta_dentro_arco:
		if abs(altura - altura_travesano) < 15.0:
			velocidad_z = -velocidad_z * 0.4
			velocidad.y = -velocidad.y * 0.5
	elif not esta_dentro_arco:
		velocidad *= 0.5

func _reiniciar_despues_de_tiro() -> void:
	await get_tree().create_timer(5.0).timeout
	
	if nodo_padre_original:
		reparent(nodo_padre_original)
		
	en_movimiento = false
	velocidad = Vector2.ZERO
	velocidad_z = 0.0
	altura = 0.0
	ya_revisado = false
	golpeo_palo = false
	fue_atajada = false
	global_position = posicion_original
	animacion.position.y = 0
	animacion.scale = Vector2(0.4, 0.4)
	animacion.play("idle")
	colision.set_deferred("disabled", false)

	if Global.ia:
		Global.turno_jugador = not Global.turno_jugador
		if not Global.turno_jugador:
			await get_tree().create_timer(1.0).timeout
			var jugador = get_node_or_null("/root/Cancha/Jugador")
			if jugador and jugador.has_method("patear_ia"):
				jugador.patear_ia()
