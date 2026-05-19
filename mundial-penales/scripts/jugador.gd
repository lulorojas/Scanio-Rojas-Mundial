extends Node2D

@export var multiplicador_fuerza: float = 3.5
@export var fuerza_maxima: float = 9999.0

var arrastrando: bool = false
var pos_inicial_click: Vector2 = Vector2.ZERO
var vector_apuntado: Vector2 = Vector2.ZERO

@onready var linea_flecha: Line2D = $Line2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var pelota: Area2D = $Pelota 
@onready var punto_caida: ColorRect = $PuntoCaida 

func _ready():
	var ruta_animaciones = "res://assets/animaciones/" + Global.equipo_seleccionado + ".tres"
	var nuevas_animaciones = load(ruta_animaciones)
	if nuevas_animaciones:
		anim.sprite_frames = nuevas_animaciones
	linea_flecha.hide()
	punto_caida.hide()
	anim.play("idle")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_mouse_position().distance_to(pelota.global_position) < 40.0:
				arrastrando = true
				pos_inicial_click = get_global_mouse_position()
				linea_flecha.clear_points()
				linea_flecha.add_point(pelota.position) 
				linea_flecha.add_point(pelota.position) 
				linea_flecha.show()
				punto_caida.hide()
		elif arrastrando and not event.pressed:
			arrastrando = false
			linea_flecha.hide()
			_patear_pelota()

	elif event is InputEventMouseMotion and arrastrando:
		vector_apuntado = (pos_inicial_click - get_global_mouse_position()) * multiplicador_fuerza
		
		if vector_apuntado.y > 0:
			vector_apuntado.y = 0
			
		if vector_apuntado.length() > fuerza_maxima:
			vector_apuntado = vector_apuntado.normalized() * fuerza_maxima
			
		linea_flecha.set_point_position(1, pelota.position + (vector_apuntado / multiplicador_fuerza))
		
		var vel_z_futura = vector_apuntado.length() * 0.35
		var tiempo_vuelo = (2.0 * vel_z_futura) / 600.0 
		punto_caida.position = (pelota.position + (vector_apuntado * tiempo_vuelo)) - (punto_caida.size / 2.0)
		punto_caida.show()

func _patear_pelota():
	if vector_apuntado.length() < 10:
		punto_caida.hide()
		return
		
	anim.play("kick")
	var fuerza_tiro = vector_apuntado
	vector_apuntado = Vector2.ZERO
	
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(pelota) and pelota.get_parent() == self:
		pelota.reparent(get_tree().current_scene) 
		pelota.en_movimiento = true
		pelota.velocidad_plana = fuerza_tiro
		pelota.velocidad_z = fuerza_tiro.length() * 0.35
		pelota.anim.play("remate")
		get_tree().create_timer(4.0).timeout.connect(pelota.queue_free)
	
	if anim.is_playing() and anim.animation == "kick":
		await anim.animation_finished
		
	anim.play("idle")
