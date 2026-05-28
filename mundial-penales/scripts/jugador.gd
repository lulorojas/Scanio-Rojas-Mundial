extends Node2D

@export var mult_fuerza = 3.1
@export var fuerza_max = 9999.0

var arrastrando = false
var click_inicio = Vector2.ZERO
var direccion = Vector2.ZERO

@onready var linea = $Line2D
@onready var anim = $AnimatedSprite2D
@onready var pelota = $Pelota

func _ready():
	var ruta = "res://assets/animaciones/" + Global.equipo_seleccionado + ".tres"
	var animaciones = load(ruta)
	if animaciones:
		anim.sprite_frames = animaciones
	linea.hide()
	anim.play("idle")

func _input(event):
	if not is_instance_valid(pelota):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_mouse_position().distance_to(pelota.global_position) < 40.0:
				arrastrando = true
				click_inicio = get_global_mouse_position()
				linea.clear_points()
				linea.add_point(pelota.position)
				linea.add_point(pelota.position)
				linea.show()
		elif arrastrando and not event.pressed:
			arrastrando = false
			linea.hide()
			patear()

	elif event is InputEventMouseMotion and arrastrando:
		direccion = (click_inicio - get_global_mouse_position()) * mult_fuerza

		if direccion.y > 0:
			direccion.y = 0
		if direccion.length() > fuerza_max:
			direccion = direccion.normalized() * fuerza_max

		linea.set_point_position(1, pelota.position + (direccion / mult_fuerza))

func patear():
	if direccion.length() < 10:
		return

	anim.play("kick")
	var fuerza = direccion
	direccion = Vector2.ZERO

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(pelota):
		if pelota.get_parent() == self:
			pelota.reparent(get_tree().current_scene)
		
		var vz = abs(fuerza.y) * 0.8
		pelota.patear(fuerza, vz)

	if anim.is_playing() and anim.animation == "kick":
		await anim.animation_finished

	anim.play("idle")
