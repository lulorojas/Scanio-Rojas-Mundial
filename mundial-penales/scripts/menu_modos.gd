extends Control

func _on_solitario_pressed() -> void:
	Global.ia = true
	Global.reiniciar_torneo()
	get_tree().change_scene_to_file("res://escenas/menuselecciones.tscn")


func _on_v_1_pressed() -> void:
	Global.ia = false
	get_tree().change_scene_to_file("res://escenas/cancha.tscn")
