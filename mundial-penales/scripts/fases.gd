extends Control

@onready var panel_octavos = $MargenCentral/VBox/GridFases/PanelOctavos
@onready var panel_cuartos = $MargenCentral/VBox/GridFases/PanelCuartos
@onready var panel_semis = $MargenCentral/VBox/GridFases/PanelSemis
@onready var panel_final = $MargenCentral/VBox/GridFases/PanelFinal

@onready var imagen_octavos = $MargenCentral/VBox/GridFases/PanelOctavos/TextureRect
@onready var imagen_cuartos = $MargenCentral/VBox/GridFases/PanelCuartos/TextureRect
@onready var imagen_semis = $MargenCentral/VBox/GridFases/PanelSemis/TextureRect
@onready var imagen_final = $MargenCentral/VBox/GridFases/PanelFinal/TextureRect

@onready var etiqueta_octavos = $MargenCentral/VBox/GridFases/PanelOctavos/Label
@onready var etiqueta_cuartos = $MargenCentral/VBox/GridFases/PanelCuartos/Label
@onready var etiqueta_semis = $MargenCentral/VBox/GridFases/PanelSemis/Label
@onready var etiqueta_final = $MargenCentral/VBox/GridFases/PanelFinal/Label

@onready var boton_octavos = $MargenCentral/VBox/GridFases/PanelOctavos/Boton
@onready var boton_cuartos = $MargenCentral/VBox/GridFases/PanelCuartos/Boton
@onready var boton_semis = $MargenCentral/VBox/GridFases/PanelSemis/Boton
@onready var boton_final = $MargenCentral/VBox/GridFases/PanelFinal/Boton

var indice_fase = {"octavos": 0, "cuartos": 1, "semis": 2, "final": 3}

func _ready():
	if not Global.torneo_activo:
		Global.iniciar_torneo()
	_actualizar_paneles()
	boton_octavos.pressed.connect(_al_presionar_fase.bind("octavos"))
	boton_cuartos.pressed.connect(_al_presionar_fase.bind("cuartos"))
	boton_semis.pressed.connect(_al_presionar_fase.bind("semis"))
	boton_final.pressed.connect(_al_presionar_fase.bind("final"))

func _actualizar_paneles():
	var ronda_actual = indice_fase.get(Global.ronda, 0)
	var imagenes = [imagen_octavos, imagen_cuartos, imagen_semis, imagen_final]
	var etiquetas = [etiqueta_octavos, etiqueta_cuartos, etiqueta_semis, etiqueta_final]
	var botones = [boton_octavos, boton_cuartos, boton_semis, boton_final]
	var nombres_fase = ["OCTAVOS", "CUARTOS", "SEMIS", "FINAL"]

	for i in range(4):
		if i < ronda_actual:
			var rival = Global.rivales_por_fase[i]
			var textura = load("res://assets/fondos/" + rival + ".png")
			if textura:
				imagenes[i].texture = textura
				imagenes[i].visible = true
			etiquetas[i].visible = false
			botones[i].text = "Repetir"
			botones[i].visible = true
			botones[i].disabled = false
		elif i == ronda_actual:
			var textura = load("res://assets/fondos/" + Global.rival_actual + ".png")
			if textura:
				imagenes[i].texture = textura
				imagenes[i].visible = true
			etiquetas[i].visible = false
			botones[i].text = "Jugar"
			botones[i].visible = true
			botones[i].disabled = false
		else:
			imagenes[i].visible = false
			etiquetas[i].visible = true
			etiquetas[i].text = nombres_fase[i]
			botones[i].text = "Bloqueado"
			botones[i].visible = true
			botones[i].disabled = true

func _al_presionar_fase(fase: String):
	var indice = indice_fase[fase]
	var ronda_actual = indice_fase.get(Global.ronda, 0)
	if indice < ronda_actual:
		Global.rival_actual = Global.rivales_por_fase[indice]
	Global.goles_jugador = 0
	Global.goles_rival = 0
	Global.penales_pateados = 0
	Global.maximo_penales = 5
	Global.resultados_jugador = []
	Global.resultados_rival = []
	Global.turno_jugador = true
	get_tree().change_scene_to_file("res://escenas/torneo.tscn")
