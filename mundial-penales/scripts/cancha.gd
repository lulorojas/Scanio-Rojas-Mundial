extends Node2D

@onready var marcador_jugador = $CanvasLayer/MarcadorJugador
@onready var marcador_rival = $CanvasLayer/MarcadorRival
@onready var circulos_jugador = $CanvasLayer/CirculosJugador
@onready var circulos_rival = $CanvasLayer/CirculosRival

func _ready():
	if not Global.torneo_activo:
		Global.goles_jugador = 0
		Global.goles_rival = 0
		Global.penales_pateados = 0
		Global.maximo_penales = 5
		Global.resultados_jugador = []
		Global.resultados_rival = []

func _process(_delta):
	marcador_jugador.text = Global.equipo.to_upper() + " " + str(Global.goles_jugador)
	marcador_rival.text = Global.rival_actual.to_upper() + " " + str(Global.goles_rival)
	_actualizar_circulos()

func _actualizar_circulos():
	for i in range(circulos_jugador.get_child_count()):
		var circulo = circulos_jugador.get_child(i)
		if i < Global.resultados_jugador.size():
			if Global.resultados_jugador[i]:
				circulo.color = Color(0.1, 0.8, 0.1, 1)
			else:
				circulo.color = Color(0.8, 0.1, 0.1, 1)
		else:
			circulo.color = Color(0.5, 0.5, 0.5, 1)
	for i in range(circulos_rival.get_child_count()):
		var circulo = circulos_rival.get_child(i)
		if i < Global.resultados_rival.size():
			if Global.resultados_rival[i]:
				circulo.color = Color(0.1, 0.8, 0.1, 1)
			else:
				circulo.color = Color(0.8, 0.1, 0.1, 1)
		else:
			circulo.color = Color(0.5, 0.5, 0.5, 1)
