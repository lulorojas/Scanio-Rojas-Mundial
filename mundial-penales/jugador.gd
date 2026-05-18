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
	linea_flecha.hide()
	anim.play("idle")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var distancia_a_pelota = get_global_mouse_position().distance_to(pelota.global_position)
			
			if distancia_a_pelota < 40.0:
				arrastrando = true
				pos_inicial_click = get_global_mouse_position()
				
				linea_flecha.clear_points()
				linea_flecha.add_point(pelota.position) 
				linea_flecha.add_point(pelota.position) 
				linea_flecha.show()
			
		elif arrastrando and not event.pressed:
			arrastrando = false
			linea_flecha.hide()
			_patear_pelota()

	elif event is InputEventMouseMotion and arrastrando:
		var pos_actual_mouse = get_global_mouse_position()
		
		vector_apuntado = (pos_inicial_click - pos_actual_mouse) * multiplicador_fuerza
		
		if vector_apuntado.y > 0:
			vector_apuntado.y = 0
			
		if vector_apuntado.length() > fuerza_maxima:
			vector_apuntado = vector_apuntado.normalized() * fuerza_maxima
			
		var punta_flecha = pelota.position + (vector_apuntado / multiplicador_fuerza)
		linea_flecha.set_point_position(1, punta_flecha)

func _patear_pelota():
	if vector_apuntado.length() < 10:
		return
		
	anim.play("kick")
	
	pelota.reparent(get_tree().current_scene) 
	
	pelota.en_movimiento = true
	pelota.velocidad_plana = vector_apuntado
	pelota.velocidad_z = vector_apuntado.length() * 0.8
	
	vector_apuntado = Vector2.ZERO
	
	get_tree().create_timer(4.0).timeout.connect(pelota.queue_free)
	
	await anim.animation_finished
	anim.play("idle")
