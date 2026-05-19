extends Node2D

@export var multiplicador_fuerza: float = 3.5
@export var fuerza_maxima: float = 1200.0

var arrastrando: bool = false
var pos_inicial_click: Vector2 = Vector2.ZERO
var vector_apuntado: Vector2 = Vector2.ZERO

@onready var linea_flecha: Line2D = $Line2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var pelota: Area2D = $Pelota 

func _ready():
	var ruta_animaciones = "res://assets/animaciones/" + Global.equipo_seleccionado + ".tres"
	var nuevas_animaciones = load(ruta_animaciones)
	if nuevas_animaciones:	 anim.sprite_frames = nuevas_animaciones
	linea_flecha.hide()
	anim.play("idle")

func _input(event):
	# 1. Click Inicial sobre la pelota
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Solo permitimos arrastrar si hace click cerca de la pelota
			var distancia_a_pelota = get_global_mouse_position().distance_to(pelota.global_position)
			
			if distancia_a_pelota < 40.0:
				arrastrando = true
				pos_inicial_click = get_global_mouse_position()
				
				linea_flecha.clear_points()
				linea_flecha.add_point(pelota.position) 
				linea_flecha.add_point(pelota.position) 
				linea_flecha.show()
			
		# 2. Soltar el click (Patear)
		elif arrastrando and not event.pressed:
			arrastrando = false
			linea_flecha.hide()
			_patear_pelota()

	# 3. Arrastrar para apuntar
	elif event is InputEventMouseMotion and arrastrando:
		var pos_actual_mouse = get_global_mouse_position()
		
		# Gomera inversa
		vector_apuntado = (pos_inicial_click - pos_actual_mouse) * multiplicador_fuerza
		
		# Bloqueo para no patear para atrás
		if vector_apuntado.y > 0:
			vector_apuntado.y = 0
			
		# Limitador de fuerza
		if vector_apuntado.length() > fuerza_maxima:
			vector_apuntado = vector_apuntado.normalized() * fuerza_maxima
			
		var punta_flecha = pelota.position + (vector_apuntado / multiplicador_fuerza)
		linea_flecha.set_point_position(1, punta_flecha)

func _patear_pelota():
	if vector_apuntado.length() < 10:
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
