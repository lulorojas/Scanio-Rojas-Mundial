extends Control

func _on_solitario_pressed() -> void:
	Global.modo = "solitario"
	Global.iniciar_torneo()
	get_tree().change_scene_to_file("res://escenas/torneo.tscn")


func _on_v_1_pressed() -> void:
	Global.modo = "1vs1"
	get_tree().change_scene_to_file("res://escenas/cancha.tscn")
