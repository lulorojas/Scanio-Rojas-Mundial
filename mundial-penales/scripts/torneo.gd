extends Control

@onready var etiqueta_fase = $Cuadricula/Fase
@onready var etiqueta_partido = $Cuadricula/Partido

func _ready():
	if not Global.torneo_activo:
		Global.iniciar_torneo()
	etiqueta_fase.text = Global.fase_actual.to_upper()
	etiqueta_partido.text = Global.equipo.to_upper() + " vs " + Global.rival_actual.to_upper()

func _al_jugar():
	Global.turno_jugador = true
	get_tree().change_scene_to_file("res://escenas/cancha.tscn")
