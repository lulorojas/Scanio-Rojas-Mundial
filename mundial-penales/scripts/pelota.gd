extends Area2D

var vel = Vector2.ZERO
var vel_z = 0.0
var altura = 0.0
var gravedad = 600.0
var se_mueve = false
var ya_revise = false
var pego_palo = false

# posiciones del arco
var palo_izq = 330.5
var palo_der = 820.5
var linea_gol = 367.0
var alto_travesano = 120.0

var escala_max = 1.0
var escala_min = 0.65
var pos_y_inicio = 0.0

@onready var anim = $AnimatedSprite2D
@onready var col = $CollisionShape2D

func _ready():
	anim.play("idle")

func patear(fuerza, vz):
	se_mueve = true
	vel = fuerza
	vel_z = vz
	altura = 0.0
	ya_revise = false
	pego_palo = false
	pos_y_inicio = global_position.y
	anim.play("remate")
	col.set_deferred("disabled", true)

func _process(delta):
	if not se_mueve:
		return

	var vz_antes = vel_z
	vel_z -= gravedad * delta
	altura += ((vz_antes + vel_z) / 2.0) * delta

	global_position += vel * delta

	# rebote en el piso
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

	# achica la pelota cuando se aleja
	if pos_y_inicio != 0:
		var prog = clamp(1.0 - (global_position.y - linea_gol) / (pos_y_inicio - linea_gol), 0.0, 1.0)
		var esc = lerp(escala_max, escala_min, prog)
		anim.scale = Vector2(esc, esc) * Vector2(0.4, 0.4)

	if not ya_revise:
		revisar_palos()
		revisar_gol()

func revisar_palos():
	if global_position.y > linea_gol or global_position.y < linea_gol - 100:
		return
	if altura > alto_travesano:
		return

	var margen = 18.0
	var toca_izq = abs(global_position.x - palo_izq) < margen and global_position.x <= palo_izq + margen
	var toca_der = abs(global_position.x - palo_der) < margen and global_position.x >= palo_der - margen

	if toca_izq or toca_der:
		print("PALO!")
		pego_palo = true
		ya_revise = true
		vel.x = -vel.x * 0.6
		vel.y = abs(vel.y) * 0.5
		vel_z *= 0.5

func revisar_gol():
	if global_position.y > linea_gol:
		return

	ya_revise = true

	var entre_palos = global_position.x > palo_izq and global_position.x < palo_der
	var abajo_travesano = altura < alto_travesano

	if entre_palos and abajo_travesano:
		print("GOOOL!")
		vel *= 0.15
		vel_z *= 0.3
	elif not abajo_travesano:
		print("Por arriba!")
	elif not entre_palos:
		print("Afuera!")
		vel *= 0.5
	else:
		if abs(altura - alto_travesano) < 15.0 and entre_palos:
			print("TRAVESAÑO!")
			vel_z = -vel_z * 0.4
			vel.y = -vel.y * 0.5
