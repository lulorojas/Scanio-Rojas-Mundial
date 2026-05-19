extends Area2D

var velocidad_plana: Vector2 = Vector2.ZERO
var velocidad_z: float = 0.0
var altura_z: float = 0.0
var gravedad: float = 600.0 

var en_movimiento: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D 
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready():
	anim.play("idle")

func _process(delta):
	if not en_movimiento:
		return

	velocidad_z -= gravedad * delta
	altura_z += velocidad_z * delta
	global_position += velocidad_plana * delta
	
	if altura_z <= 0:
		altura_z = 0
		if abs(velocidad_z) > 100:
			velocidad_z = -velocidad_z * 0.25
			velocidad_plana *= 0.7
		else:
			velocidad_z = 0
			velocidad_plana *= 0.92
			
			if velocidad_plana.length() < 15.0:
				velocidad_plana = Vector2.ZERO
				en_movimiento = false 
				anim.play("idle") 

	anim.position.y = -altura_z
	colision.position.y = -altura_z

func _on_area_entered(area):
	if area.is_in_group("arco"):
		print("¡GOOOOOOOOOOL!")
		velocidad_plana = Vector2.ZERO 
		velocidad_z = 0
		en_movimiento = false
		anim.play("idle")
		
	elif area.is_in_group("afuera"):
		print("¡Uhhh, se fue desviada!")
		velocidad_plana = Vector2.ZERO 
		velocidad_z = 0
		en_movimiento = false
		anim.play("idle")
