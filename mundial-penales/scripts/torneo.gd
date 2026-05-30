extends Control

@onready var label_fase = $Cuadricula/Fase
@onready var label_partido = $Cuadricula/Partido

func _ready():
	if not Global.torneo_activo:
		Global.iniciar_torneo()
	label_fase.text = Global.fase_actual.to_upper()
	label_partido.text = Global.equipo.to_upper() + " vs " + Global.rival_actual.to_upper()

func _on_jugar_pressed():
	Global.turno_jugador = true
	get_tree().change_scene_to_file("res://escenas/cancha.tscn")
