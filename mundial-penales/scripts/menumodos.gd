extends Control

@onready var boton_solitario: Button = $Cuadricula/BotonSolitario
@onready var boton_1vs1: Button = $Cuadricula/Boton1VS1

func _ready():
	boton_solitario.pressed.connect(_on_boton_solitario_pressed)
	boton_1vs1.pressed.connect(_on_boton_1vs_1_pressed)




func _on_boton_solitario_pressed() -> void:
	Global.contra_ia = true
	get_tree().change_scene_to_file("res://escenas/menuselecciones.tscn")


func _on_boton_1vs_1_pressed() -> void:
	Global.contra_ia = true
	get_tree().change_scene_to_file("res://escenas/menuselecciones.tscn")
