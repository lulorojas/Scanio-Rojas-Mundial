extends Control

func _iniciar_partido(seleccion: String):
	Global.equipo = seleccion
	if Global.ia:
		get_tree().change_scene_to_file("res://escenas/torneo.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/cancha.tscn")

func _on_boton_españa_pressed() -> void:
	_iniciar_partido("espana")

func _on_boton_italia_pressed() -> void:
	_iniciar_partido("italia")

func _on_boton_belgica_pressed() -> void:
	_iniciar_partido("belgica")

func _on_boton_francia_pressed() -> void:
	_iniciar_partido("francia")

func _on_boton_peru_pressed() -> void:
	_iniciar_partido("peru")

func _on_boton_uruguay_pressed() -> void:
	_iniciar_partido("uruguay")

func _on_boton_brasil_pressed() -> void:
	_iniciar_partido("brasil")

func _on_boton_argentina_pressed() -> void:
	_iniciar_partido("argentina")

func _on_boton_korea_del_sur_pressed() -> void:
	_iniciar_partido("korea_del_sur")

func _on_boton_inglaterra_pressed() -> void:
	_iniciar_partido("inglaterra")

func _on_boton_japon_pressed() -> void:
	_iniciar_partido("japon")

func _on_boton_sudafrica_pressed() -> void:
	_iniciar_partido("sudafrica")
