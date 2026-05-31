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
var maximo_penales: int = 5

var equipos_torneo: Array = [
	"argentina", "brasil", "francia", "inglaterra",
	"belgica", "japon", "korea_del_sur", "sudafrica",
	"espana", "italia", "peru", "uruguay"
]
var rivales_restantes: Array = []
var rivales_jugados: Array = []
var rivales_por_fase: Array = []
var resultados_jugador: Array = []
var resultados_rival: Array = []


func iniciar_torneo():
	torneo_activo = true
	ronda = "octavos"
	fase_actual = "octavos de final"
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	maximo_penales = 5
	resultados_jugador = []
	resultados_rival = []
	rivales_jugados = []
	rivales_restantes = equipos_torneo.duplicate()
	rivales_restantes.erase(equipo)
	rivales_restantes.shuffle()
	rivales_por_fase = []
	for i in range(4):
		rivales_por_fase.append(rivales_restantes[i])
	rival_actual = rivales_por_fase[0]


func avanzar_ronda():
	rivales_jugados.append(rival_actual)
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	maximo_penales = 5
	resultados_jugador = []
	resultados_rival = []
	turno_jugador = true
	if ronda == "octavos":
		ronda = "cuartos"
		fase_actual = "cuartos de final"
		rival_actual = rivales_por_fase[1]
	elif ronda == "cuartos":
		ronda = "semis"
		fase_actual = "semifinal"
		rival_actual = rivales_por_fase[2]
	elif ronda == "semis":
		ronda = "final"
		fase_actual = "final"
		rival_actual = rivales_por_fase[3]
	else:
		return


func reiniciar_torneo():
	torneo_activo = false
	goles_jugador = 0
	goles_rival = 0
	penales_pateados = 0
	maximo_penales = 5
	ronda = "octavos"
	fase_actual = "octavos de final"
	turno_jugador = true
	rivales_jugados = []
	rivales_por_fase = []
	resultados_jugador = []
	resultados_rival = []
