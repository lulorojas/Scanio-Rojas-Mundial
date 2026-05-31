extends CanvasLayer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(evento):
	if evento.is_action_pressed("ui_cancel"):
		if visible:
			_cerrar()
		else:
			_abrir()

func _abrir():
	visible = true
	get_tree().paused = true

func _cerrar():
	visible = false
	get_tree().paused = false

func _al_reiniciar():
	get_tree().paused = false
	Global.goles_jugador = 0
	Global.goles_rival = 0
	Global.penales_pateados = 0
	Global.maximo_penales = 5
	Global.resultados_jugador = []
	Global.resultados_rival = []
	Global.turno_jugador = true
	get_tree().reload_current_scene()

func _al_volver():
	get_tree().paused = false
	if Global.torneo_activo:
		var indice_fase = {"octavos": 0, "cuartos": 1, "semis": 2, "final": 3}
		var indice = indice_fase.get(Global.ronda, 0)
		Global.rival_actual = Global.rivales_por_fase[indice]
		get_tree().change_scene_to_file("res://escenas/fases.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/menu_modos.tscn")
