extends Area2D

var velocidad_plana: Vector2 = Vector2.ZERO
var velocidad_z: float = 0.0
var altura_z: float = 0.0
var gravedad: float = 1500.0

var en_movimiento: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _process(delta):
	if not en_movimiento:
		return

	velocidad_z -= gravedad * delta
	altura_z += velocidad_z * delta
	global_position += velocidad_plana * delta
	
	if altura_z <= 0:
		altura_z = 0
		if abs(velocidad_z) > 200:
			velocidad_z = -velocidad_z * 0.25
			velocidad_plana *= 0.7
		else:
			velocidad_z = 0
			velocidad_plana *= 0.92

	sprite.position.y = -altura_z
	colision.position.y = -altura_z

func _on_body_entered(body):
	if body.is_in_group("arquero"):
		print("¡ATAJADA!")
