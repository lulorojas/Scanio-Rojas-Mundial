extends Control

@onready var etiqueta_titulo = $Titulo
@onready var etiqueta_resultado = $Resultado

func _ready():
	if Global.goles_jugador > Global.goles_rival:
		etiqueta_titulo.text = "GANASTE!"
	else:
		etiqueta_titulo.text = "ELIMINADO"
	etiqueta_resultado.text = Global.equipo.to_upper() + " " + str(Global.goles_jugador) + " - " + str(Global.goles_rival) + " " + Global.rival_actual.to_upper()

func _al_volver():
	if Global.torneo_activo:
		if Global.ronda == "octavos":
			Global.reiniciar_torneo()
			Global.iniciar_torneo()
			get_tree().change_scene_to_file("res://escenas/fases.tscn")
		else:
			Global.goles_jugador = 0
			Global.goles_rival = 0
			Global.penales_pateados = 0
			Global.maximo_penales = 5
			Global.resultados_jugador = []
			Global.resultados_rival = []
			Global.turno_jugador = true
			var indice_fase = {"octavos": 0, "cuartos": 1, "semis": 2, "final": 3}
			var indice = indice_fase.get(Global.ronda, 0)
			Global.rival_actual = Global.rivales_por_fase[indice]
			get_tree().change_scene_to_file("res://escenas/fases.tscn")
	else:
		Global.reiniciar_torneo()
		get_tree().change_scene_to_file("res://escenas/menu_modos.tscn")
