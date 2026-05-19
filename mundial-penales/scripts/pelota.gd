extends Area2D

var velocidad_plana: Vector2 = Vector2.ZERO
var velocidad_z: float = 0.0
var altura_z: float = 0.0
var gravedad: float = 600.0
var en_movimiento: bool = false
var pego_en_palo: bool = false

# Altura (en px de eje Z) a la que está el travesaño.
# Ajustá este valor según tu escena. El travesaño está en y=160.25
# y el suelo del arco en y≈337 (160+203/2 aprox), la diferencia visual
# entre el suelo y el travesaño son ~177px → ese es el "techo" en Z.
const ALTURA_TRAVESANO: float = 170.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var _nodo_palos: Area2D = null
var _travesano_shape: CollisionShape2D = null

func _ready():
	anim.play("idle")

func _process(delta):
	if not en_movimiento:
		return

	var velocidad_z_anterior = velocidad_z
	velocidad_z -= gravedad * delta
	altura_z += ((velocidad_z_anterior + velocidad_z) / 2.0) * delta

	global_position += velocidad_plana * delta

	# ── Lógica del travesaño ──────────────────────────────────────────
	# Si la pelota vuela por ENCIMA del travesaño, desactivamos su collision
	# para que pueda pasar. Cuando baja al nivel del travesaño, la reactivamos.
	_actualizar_collision_travesano()

	# ── Rebote en el suelo ────────────────────────────────────────────
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

func _actualizar_collision_travesano():
	# Buscamos el nodo Palos en la escena la primera vez
	if _nodo_palos == null:
		_nodo_palos = get_tree().current_scene.get_node_or_null("Palos")
		if _nodo_palos:
			_travesano_shape = _nodo_palos.get_node_or_null("travesano")

	if _travesano_shape == null:
		return

	# La pelota está por encima del travesaño → desactivar su collision
	# para que no bloquee el paso. Cuando baja → reactivar.
	_travesano_shape.disabled = (altura_z > ALTURA_TRAVESANO)

func _on_area_entered(area):
	if area.is_in_group("palos"):
		pego_en_palo = true
		print("¡PALO!")
		velocidad_plana.y = -velocidad_plana.y * 0.5
		velocidad_plana.x = -velocidad_plana.x * 0.5
		velocidad_z *= 0.5

	elif area.is_in_group("arco"):
		if not pego_en_palo:
			print("¡GOOOOOOOOOOL!")
		else:
			print("¡Pegó en el palo y entró! (Anulado)")
		velocidad_plana *= 0.15

	elif area.is_in_group("afuera"):
		print("¡Uhhh, se fue desviada!")
