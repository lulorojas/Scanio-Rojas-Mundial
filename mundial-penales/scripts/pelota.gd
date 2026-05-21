extends Area2D

var velocidad_plana: Vector2 = Vector2.ZERO  # Movimiento en el plano del suelo (X, Y pantalla)
var velocidad_z: float = 0.0                 # Velocidad vertical (altura simulada)
var altura_z: float = 0.0                    # Altura actual de la pelota
var gravedad: float = 600.0
var en_movimiento: bool = false
var resultado_definido: bool = false

# ── Dimensiones del arco (en coordenadas de escena) ──────────────────
# Estos valores representan los límites del arco en la cancha.
# Se configuran desde la escena o se pueden ajustar acá.
const PALO_IZQ_X: float = 330.5       # X del palo izquierdo
const PALO_DER_X: float = 820.5       # X del palo derecho
const LINEA_GOL_Y: float = 367.0      # Y donde está la línea de gol (base del arco)
const ALTURA_TRAVESANO: float = 165.0  # Altura máxima del arco (en píxeles de falso eje Z)

# Escala de perspectiva: la pelota se achica al alejarse (acercarse al arco)
const ESCALA_INICIAL: float = 1.0
const ESCALA_MINIMA: float = 0.65
var _pos_inicio_y: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var _sombra: Sprite2D = null

func _ready():
	anim.play("idle")
	# Crear sombra visual
	_sombra = Sprite2D.new()
	_sombra.texture = preload("res://assets/extras/pelota.png") if ResourceLoader.exists("res://assets/extras/pelota.png") else null
	if _sombra.texture:
		_sombra.modulate = Color(0, 0, 0, 0.3)
		_sombra.scale = Vector2(0.3, 0.15)
		add_child(_sombra)
	else:
		_sombra.queue_free()
		_sombra = null

func iniciar_tiro(fuerza: Vector2, vel_z: float):
	en_movimiento = true
	velocidad_plana = fuerza
	velocidad_z = vel_z
	altura_z = 0.0
	resultado_definido = false
	_pos_inicio_y = global_position.y
	anim.play("remate")
	# Desactivar colisiones de Godot - usamos detección manual
	colision.set_deferred("disabled", true)

func _process(delta):
	if not en_movimiento:
		return

	# ── Física del falso eje Z ────────────────────────────────────────
	var velocidad_z_anterior = velocidad_z
	velocidad_z -= gravedad * delta
	altura_z += ((velocidad_z_anterior + velocidad_z) / 2.0) * delta

	# ── Movimiento en el plano del suelo ──────────────────────────────
	global_position += velocidad_plana * delta

	# ── Rebote en el suelo ────────────────────────────────────────────
	if altura_z <= 0:
		altura_z = 0
		if abs(velocidad_z) > 80:
			velocidad_z = -velocidad_z * 0.3
			velocidad_plana *= 0.7
		else:
			velocidad_z = 0
			velocidad_plana *= 0.92
			if velocidad_plana.length() < 10.0:
				velocidad_plana = Vector2.ZERO
				en_movimiento = false
				anim.play("idle")

	# ── Visual: solo el sprite sube, la colisión se queda en el suelo ─
	anim.position.y = -altura_z

	# ── Sombra en el suelo ────────────────────────────────────────────
	if _sombra:
		_sombra.position.y = 0  # Siempre al nivel del suelo

	# ── Escala por perspectiva ────────────────────────────────────────
	if _pos_inicio_y != 0:
		var progreso = clamp(1.0 - (global_position.y - LINEA_GOL_Y) / (_pos_inicio_y - LINEA_GOL_Y), 0.0, 1.0)
		var nueva_escala = lerp(ESCALA_INICIAL, ESCALA_MINIMA, progreso)
		anim.scale = Vector2(nueva_escala, nueva_escala) * Vector2(0.36, 0.36)

	# ── Detección manual de gol / palo / afuera ───────────────────────
	if not resultado_definido:
		_verificar_palos()
		_verificar_resultado()

var _pego_palo: bool = false

func _verificar_palos():
	# Verificar palos continuamente mientras la pelota está en la zona del arco
	if global_position.y > LINEA_GOL_Y or global_position.y < LINEA_GOL_Y - 100:
		return
	if altura_z > ALTURA_TRAVESANO:
		return
	
	var margen_palo = 18.0
	var pega_palo_izq = abs(global_position.x - PALO_IZQ_X) < margen_palo and global_position.x <= PALO_IZQ_X + margen_palo
	var pega_palo_der = abs(global_position.x - PALO_DER_X) < margen_palo and global_position.x >= PALO_DER_X - margen_palo
	
	if pega_palo_izq or pega_palo_der:
		print("¡PALO!")
		_pego_palo = true
		resultado_definido = true
		# Rebote hacia afuera
		velocidad_plana.x = -velocidad_plana.x * 0.6
		velocidad_plana.y = abs(velocidad_plana.y) * 0.5  # Siempre rebota hacia abajo (Y positivo = hacia el jugador)
		velocidad_z *= 0.5

func _verificar_resultado():
	# Solo verificar cuando la pelota llega a la línea del arco
	if global_position.y > LINEA_GOL_Y:
		return

	# La pelota cruzó la línea de gol
	resultado_definido = true
	
	# Calcular la altura exacta en el momento de cruzar la línea
	# (interpolar porque pudo haber cruzado entre frames)
	var altura_en_linea = altura_z
	print("Altura al cruzar: ", altura_en_linea, " | Travesaño: ", ALTURA_TRAVESANO)

	var dentro_palos = global_position.x > PALO_IZQ_X and global_position.x < PALO_DER_X
	var debajo_travesano = altura_en_linea < ALTURA_TRAVESANO

	if dentro_palos and debajo_travesano:
		# ¡GOL! La pelota entró dentro del arco
		print("¡GOOOOOOOOOOL!")
		velocidad_plana *= 0.15
		velocidad_z *= 0.3
	elif not debajo_travesano:
		# La pelota pasó por ENCIMA del travesaño
		print("¡Por arriba del travesaño!")
		# Sigue su trayectoria, no rebota
	elif not dentro_palos:
		# Se fue afuera por los costados
		print("¡Afuera!")
		velocidad_plana *= 0.5
	else:
		# Pega en el travesaño (está justo al límite de altura)
		if abs(altura_z - ALTURA_TRAVESANO) < 15.0 and dentro_palos:
			print("¡TRAVESAÑO!")
			velocidad_z = -velocidad_z * 0.4
			velocidad_plana.y = -velocidad_plana.y * 0.5

# Ya no usamos _on_area_entered para la lógica del arco
func _on_area_entered(_area):
	pass
