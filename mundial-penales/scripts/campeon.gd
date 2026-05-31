extends Control

@onready var etiqueta_titulo = $Titulo
@onready var etiqueta_equipo = $Equipo

func _ready():
	etiqueta_titulo.text = "CAMPEON DEL MUNDO!"
	etiqueta_equipo.text = Global.equipo.to_upper()

func _al_volver() -> void:
	Global.reiniciar_torneo()
	get_tree().change_scene_to_file("res://escenas/menu_modos.tscn")
