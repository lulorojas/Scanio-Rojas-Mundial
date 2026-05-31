extends Node2D

@export var multiplicador_fuerza: float = 3.1
@export var fuerza_maxima: float = 9999.0

var arrastrando = false
var inicio_click = Vector2.ZERO
var direccion_tiro = Vector2.ZERO

var precision = {
	"octavos": 0.15,
	"cuartos": 0.20,
	"semis": 0.10,
	"final": 0.05
}

@onready var linea_tiro = $Line2D
@onready var animacion = $AnimatedSprite2D
@onready var pelota = $Pelota


func _ready():
	var ruta = "res://assets/animaciones/" + Global.equipo + ".tres"
	var recurso = load(ruta)
	if recurso:
		animacion.sprite_frames = recurso
	linea_tiro.hide()
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
				linea_tiro.clear_points()
				linea_tiro.add_point(pelota.position)
				linea_tiro.add_point(pelota.position)
				linea_tiro.show()
		elif arrastrando and not evento.pressed:
			arrastrando = false
			linea_tiro.hide()
			patear()
	elif evento is InputEventMouseMotion and arrastrando:
		direccion_tiro = (inicio_click - get_global_mouse_position()) * multiplicador_fuerza
		if direccion_tiro.y > 0:
			direccion_tiro.y = 0
		if direccion_tiro.length() > fuerza_maxima:
			direccion_tiro = direccion_tiro.normalized() * fuerza_maxima
		linea_tiro.set_point_position(1, pelota.position + (direccion_tiro / multiplicador_fuerza))


func patear():
	if direccion_tiro.length() < 10:
		return
	animacion.play("kick")
	var fuerza = direccion_tiro
	direccion_tiro = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(pelota):
		if pelota.get_parent() == self:
			pelota.reparent(get_tree().current_scene)
		var velocidad_z = abs(fuerza.y) * 0.8
		pelota.patear(fuerza, velocidad_z)
	if animacion.is_playing() and animacion.animation == "kick":
		await animacion.animation_finished
	animacion.play("idle")


func patear_ia():
	if not is_instance_valid(pelota):
		return
	animacion.play("kick")
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(pelota):
		return
	if pelota.get_parent() == self:
		pelota.reparent(get_tree().current_scene)
	var fuerza = _calcular_tiro()
	var multiplicador_altura = randf_range(0.3, 0.5)
	var velocidad_z = abs(fuerza.y) * multiplicador_altura
	pelota.patear(fuerza, velocidad_z)
	if animacion.is_playing() and animacion.animation == "kick":
		await animacion.animation_finished
	animacion.play("idle")


func _calcular_tiro() -> Vector2:
	var probabilidad_fallo = precision.get(Global.ronda, 0.20)
	var falla = randf() < probabilidad_fallo
	var fuerza_base = randf_range(550.0, 750.0)
	var angulo_x = 0.0
	if falla:
		var tipo = randi_range(0, 2)
		if tipo == 0:
			angulo_x = randf_range(-50.0, 50.0)
			fuerza_base = randf_range(300.0, 450.0)
		elif tipo == 1:
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
