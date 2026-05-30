extends Control

@onready var label_titulo = $Titulo
@onready var label_equipo = $Equipo

func _ready():
	label_titulo.text = "CAMPEON DEL MUNDO!"
	label_equipo.text = Global.equipo.to_upper()

func _on_volver_pressed() -> void:
	Global.reiniciar_torneo()
	get_tree().change_scene_to_file("res://escenas/menu_modos.tscn")
