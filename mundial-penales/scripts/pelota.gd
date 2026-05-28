extends Area2D

var vel = Vector2.ZERO
var vel_z = 0.0
var altura = 0.0
var gravedad = 600.0
var se_mueve = false
var ya_revise = false
var pego_palo = false
var atajada = false

var palo_izq = 330.5
var palo_der = 820.5
var linea_gol = 337.0
var alto_travesano = 120.0

var escala_max = 1.0
var escala_min = 0.65
var pos_y_inicio = 0.0
var posicion_original: Vector2
var padre_original: Node

@onready var anim = $AnimatedSprite2D
@onready var col = $CollisionShape2D

func _ready():
	anim.play("idle")
	posicion_original = global_position
	padre_original = get_parent()

func patear(fuerza, vz):
	se_mueve = true
	vel = fuerza
	vel_z = vz
	altura = 0.0
	ya_revise = false
	pego_palo = false
	atajada = false
	pos_y_inicio = global_position.y
	anim.play("remate")
	col.set_deferred("disabled", true)

	if Global.contra_ia:
		var arquero = get_node_or_null("/root/Cancha/arquero")
		if arquero and arquero.has_method("reaccionar_ia"):
			arquero.reaccionar_ia()

	_resetear_despues_de_patear()

func _process(delta):
	if not se_mueve:
		return

	var vz_antes = vel_z
	vel_z -= gravedad * delta
	altura += ((vz_antes + vel_z) / 2.0) * delta

	global_position += vel * delta

	if col.disabled and global_position.y < linea_gol + 250 and not atajada:
		col.set_deferred("disabled", false)

	if altura <= 0:
		altura = 0
		if abs(vel_z) > 80:
			vel_z = -vel_z * 0.3
			vel *= 0.7
		else:
			vel_z = 0
			vel *= 0.92
			if vel.length() < 10.0:
				vel = Vector2.ZERO
				se_mueve = false
				anim.play("idle")

	anim.position.y = -altura

	if pos_y_inicio != 0:
		var prog = clamp(1.0 - (global_position.y - linea_gol) / (pos_y_inicio - linea_gol), 0.0, 1.0)
		var esc = lerp(escala_max, escala_min, prog)
		anim.scale = Vector2(esc, esc) * Vector2(0.4, 0.4)

	if not ya_revise:
		revisar_atajada()
		revisar_palos()
		revisar_gol()

func revisar_atajada():
	if atajada:
		return
	var arquero = get_node_or_null("/root/Cancha/arquero")
	if arquero == null:
		return
	if arquero.esta_ocupado == false:
		return
	var pos_arq = arquero.colision.global_position
	var dif_x = abs(global_position.x - pos_arq.x)
	var dif_y = abs(global_position.y - pos_arq.y)
	if dif_x < 55 and dif_y < 90:
		atajada = true
		ya_revise = true
		vel.x = -vel.x * 0.5
		vel.y = abs(vel.y) * 0.6
		vel_z = vel_z * 0.3
		col.set_deferred("disabled", true)

func revisar_palos():
	if global_position.y > linea_gol or global_position.y < linea_gol - 100:
		return
	if altura > alto_travesano:
		return

	var margen = 18.0
	var toca_izq = abs(global_position.x - palo_izq) < margen and global_position.x <= palo_izq + margen
	var toca_der = abs(global_position.x - palo_der) < margen and global_position.x >= palo_der - margen

	if toca_izq or toca_der:
		pego_palo = true
		ya_revise = true
		vel.x = -vel.x * 0.6
		vel.y = abs(vel.y) * 0.5
		vel_z *= 0.5

func revisar_gol():
	if global_position.y > linea_gol:
		return
	if atajada:
		return

	ya_revise = true

	var entre_palos = global_position.x > palo_izq and global_position.x < palo_der
	var abajo_travesano = altura < alto_travesano

	if entre_palos and abajo_travesano:
		vel *= 0.15
		vel_z *= 0.3
	elif not abajo_travesano:
		pass
	elif not entre_palos:
		vel *= 0.5
	else:
		if abs(altura - alto_travesano) < 15.0 and entre_palos:
			vel_z = -vel_z * 0.4
			vel.y = -vel.y * 0.5

func _resetear_despues_de_patear() -> void:
	await get_tree().create_timer(5.0).timeout
	
	if padre_original != null:
		reparent(padre_original)
		
	se_mueve = false
	vel = Vector2.ZERO
	vel_z = 0.0
	altura = 0.0
	ya_revise = false
	pego_palo = false
	atajada = false
	global_position = posicion_original
	anim.position.y = 0
	anim.scale = Vector2(0.4, 0.4)
	anim.play("idle")
	col.set_deferred("disabled", false)
