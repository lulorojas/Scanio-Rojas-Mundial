extends Node

var equipo: String = "argentina"
var rival_actual: String = "sudafrica"
var ia: bool = false
var ronda: String = "octavos"
var turno_jugador: bool = true
var fase_actual: String = "octavos de final"

var torneo_activo: bool = false
var goles_jugador: int = 0
var goles_rival: int = 0
var penales_pateados: int = 0
var max_penales: int = 5

var equipos_torneo: Array = [
	"argentina", "brasil", "francia", "inglaterra",
	"belgica", "japon", "korea_del_sur", "sudafrica",
	"espana", "italia", "peru", "uruguay"
]
var rivales_restantes: Array = []


func iniciar_torneo():
	torneo_activo = true
	ronda = "octavos"
	fase_actual = "octavos de final"
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	rivales_restantes = equipos_torneo.duplicate()
	rivales_restantes.erase(equipo)
	rivales_restantes.shuffle()
	rival_actual = rivales_restantes.pop_front()


func avanzar_ronda():
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	turno_jugador = true
	if ronda == "octavos":
		ronda = "cuartos"
		fase_actual = "cuartos de final"
	elif ronda == "cuartos":
		ronda = "semis"
		fase_actual = "semifinal"
	elif ronda == "semis":
		ronda = "final"
		fase_actual = "final"
	else:
		return
	if rivales_restantes.size() > 0:
		rival_actual = rivales_restantes.pop_front()
	else:
		var opciones = equipos_torneo.duplicate()
		opciones.erase(equipo)
		opciones.shuffle()
		rival_actual = opciones[0]


func reiniciar_torneo():
	torneo_activo = false
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	ronda = "octavos"
	fase_actual = "octavos de final"
	turno_jugador = true
