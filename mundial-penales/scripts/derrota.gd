extends Control

@onready var label_titulo = $Titulo
@onready var label_resultado = $Resultado

func _ready():
	if Global.goles_jugador > Global.goles_rival:
		label_titulo.text = "GANASTE!"
	else:
		label_titulo.text = "ELIMINADO"
	label_resultado.text = Global.equipo.to_upper() + " " + str(Global.goles_jugador) + " - " + str(Global.goles_rival) + " " + Global.rival_actual.to_upper()

func _on_volver_pressed():
	Global.reiniciar_torneo()
	get_tree().change_scene_to_file("res://escenas/menu_modos.tscn")
