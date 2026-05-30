extends Node2D

@onready var marcador1 = $CanvasLayer/Marcador1
@onready var marcador2 = $CanvasLayer/Marcador2

func _ready():
	if not Global.torneo_activo:
		Global.goles_jugador = 0
		Global.goles_rival = 0
		Global.penales_pateados = 0
		Global.max_penales = 5

func _process(_delta):
	marcador1.text = Global.equipo.to_upper() + " " + str(Global.goles_jugador)
	marcador2.text = Global.rival_actual.to_upper() + " " + str(Global.goles_rival)
