extends Node2D

@export var mult_fuerza: float = 3.1
@export var fuerza_max: float = 9999.0

var arrastrando = false
var inicio_click = Vector2.ZERO
var dir_tiro = Vector2.ZERO

var precision = {
	"octavos": 0.15,
	"cuartos": 0.20,
	"semis": 0.10,
	"final": 0.05
}

@onready var linea = $Line2D
@onready var anim = $AnimatedSprite2D
@onready var pelota = $Pelota


func _ready():
	var ruta = "res://assets/animaciones/" + Global.equipo + ".tres"
	var recurso = load(ruta)
	if recurso:
		anim.sprite_frames = recurso
	linea.hide()
	anim.play("idle")


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
				linea.clear_points()
				linea.add_point(pelota.position)
				linea.add_point(pelota.position)
				linea.show()
		elif arrastrando and not evento.pressed:
			arrastrando = false
			linea.hide()
			patear()
	elif evento is InputEventMouseMotion and arrastrando:
		dir_tiro = (inicio_click - get_global_mouse_position()) * mult_fuerza
		if dir_tiro.y > 0:
			dir_tiro.y = 0
		if dir_tiro.length() > fuerza_max:
			dir_tiro = dir_tiro.normalized() * fuerza_max
		linea.set_point_position(1, pelota.position + (dir_tiro / mult_fuerza))


func patear():
	if dir_tiro.length() < 10:
		return
	anim.play("kick")
	var fuerza = dir_tiro
	dir_tiro = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(pelota):
		if pelota.get_parent() == self:
			pelota.reparent(get_tree().current_scene)
		var vz = abs(fuerza.y) * 0.8
		pelota.patear(fuerza, vz)
	if anim.is_playing() and anim.animation == "kick":
		await anim.animation_finished
	anim.play("idle")


func patear_ia():
	if not is_instance_valid(pelota):
		return
	anim.play("kick")
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(pelota):
		return
	if pelota.get_parent() == self:
		pelota.reparent(get_tree().current_scene)
	var fuerza = _calcular_tiro()
	var mult_alt = randf_range(0.3, 0.5)
	var vz = abs(fuerza.y) * mult_alt
	pelota.patear(fuerza, vz)
	if anim.is_playing() and anim.animation == "kick":
		await anim.animation_finished
	anim.play("idle")


func _calcular_tiro() -> Vector2:
	var chance = precision.get(Global.ronda, 0.20)
	var falla = randf() < chance
	var fuerza_base = randf_range(550.0, 750.0)
	var ang_x = 0.0
	if falla:
		var tipo = randi_range(0, 2)
		if tipo == 0:
			ang_x = randf_range(-50.0, 50.0)
			fuerza_base = randf_range(300.0, 450.0)
		elif tipo == 1:
			ang_x = randf_range(-30.0, 30.0)
			fuerza_base = randf_range(800.0, 1000.0)
		else:
			ang_x = 0.0
			fuerza_base = randf_range(400.0, 550.0)
	else:
		var lado = randi_range(0, 1)
		if lado == 0:
			ang_x = randf_range(-280.0, -180.0)
		else:
			ang_x = randf_range(180.0, 280.0)
	return Vector2(ang_x, -fuerza_base)
