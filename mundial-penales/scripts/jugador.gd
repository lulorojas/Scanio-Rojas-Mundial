extends Node2D

@export var mult_fuerza: float = 3.1
@export var fuerza_max: float = 9999.0

var arrastrando: bool = false
var inicio_click: Vector2 = Vector2.ZERO
var direccion_tiro: Vector2 = Vector2.ZERO

var precision: Dictionary = {
	"octavos": 0.15,
	"cuartos": 0.20,
	"semis": 0.10,
	"final": 0.05
}

@onready var linea_guia = $Line2D
@onready var animacion = $AnimatedSprite2D
@onready var pelota = $Pelota

func _ready():
	var ruta_animacion = "res://assets/animaciones/" + Global.equipo + ".tres"
	var recursos_anim = load(ruta_animacion)
	if recursos_anim:
		animacion.sprite_frames = recursos_anim
	linea_guia.hide()
	animacion.play("idle")

func _input(evento):
	if not is_instance_valid(pelota):
		return
	if Global.ia and not Global.turno_jugador:
		return

	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			if get_global_mouse_position().distance_to(pelota.global_position) < 40.0:
				arrastrando = true
				inicio_click = get_global_mouse_position()
				linea_guia.clear_points()
				linea_guia.add_point(pelota.position)
				linea_guia.add_point(pelota.position)
				linea_guia.show()
		elif arrastrando and not evento.pressed:
			arrastrando = false
			linea_guia.hide()
			patear()

	elif evento is InputEventMouseMotion and arrastrando:
		direccion_tiro = (inicio_click - get_global_mouse_position()) * mult_fuerza

		if direccion_tiro.y > 0:
			direccion_tiro.y = 0
		if direccion_tiro.length() > fuerza_max:
			direccion_tiro = direccion_tiro.normalized() * fuerza_max

		linea_guia.set_point_position(1, pelota.position + (direccion_tiro / mult_fuerza))

func patear():
	if direccion_tiro.length() < 10:
		return

	animacion.play("kick")
	var fuerza_aplicada = direccion_tiro
	direccion_tiro = Vector2.ZERO

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(pelota):
		if pelota.get_parent() == self:
			pelota.reparent(get_tree().current_scene)
		
		var velocidad_z = abs(fuerza_aplicada.y) * 0.8
		pelota.patear(fuerza_aplicada, velocidad_z)

	if animacion.is_playing() and animacion.animation == "kick":
		await animacion.animation_finished

	animacion.play("idle")

func patear_ia() -> void:
	if not is_instance_valid(pelota):
		return

	animacion.play("kick")
	await get_tree().create_timer(0.5).timeout

	if not is_instance_valid(pelota):
		return

	if pelota.get_parent() == self:
		pelota.reparent(get_tree().current_scene)

	var fuerza_ia = _calcular_tiro()
	var velocidad_z_ia = abs(fuerza_ia.y) * 0.8
	pelota.patear(fuerza_ia, velocidad_z_ia)

	if animacion.is_playing() and animacion.animation == "kick":
		await animacion.animation_finished

	animacion.play("idle")

func _calcular_tiro() -> Vector2:
	var chance_error = precision.get(Global.ronda, 0.20)
	var falla = randf() < chance_error

	var fuerza_base = randf_range(550.0, 750.0)
	var angulo_x: float = 0.0

	if falla:
		var tipo_fallo = randi_range(0, 2)
		if tipo_fallo == 0:
			angulo_x = randf_range(-50.0, 50.0)
			fuerza_base = randf_range(300.0, 450.0)
		elif tipo_fallo == 1:
			angulo_x = randf_range(-30.0, 30.0)
			fuerza_base = randf_range(800.0, 1000.0)
		else:
			angulo_x = 0.0
			fuerza_base = randf_range(400.0, 550.0)
	else:
		var lado = randi_range(0, 1)
		if lado == 0:
			angulo_x = randf_range(-280.0, -180.0)
		else:
			angulo_x = randf_range(180.0, 280.0)

	return Vector2(angulo_x, -fuerza_base)
