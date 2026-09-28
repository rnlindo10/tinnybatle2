@tool
extends Node2D

const FONTE := 0
const LARGURA := 38
const ALTURA := 19

const GRAMA := Vector2i(0, 0)
const GRAMAS_ENFEITADAS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const AGUAS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
const ARVORES: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)]
const PREDIOS: Array[Vector2i] = [Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)]
const CARROS: Array[Vector2i] = [Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4)]
const BARCO := Vector2i(10, 4)

const INICIO := Vector2i(2, 7)

const TRECHOS_PISTA := [
	[Vector2i(1, 5), Vector2i(12, 5)],
	[Vector2i(12, 5), Vector2i(12, 12)],
	[Vector2i(12, 12), Vector2i(20, 12)],
	[Vector2i(18, 3), Vector2i(18, 17)],
	[Vector2i(4, 16), Vector2i(18, 16)],
]

const AGUAS_RETANGULOS := [
	Rect2i(3, 2, 3, 2),
	Rect2i(6, 9, 2, 4),
	Rect2i(22, 10, 8, 6),
	Rect2i(31, 14, 4, 3),
]

const POS_PREDIOS := [
	Vector2i(5, 7), Vector2i(6, 7), Vector2i(9, 8), Vector2i(14, 7), Vector2i(15, 7),
	Vector2i(21, 6), Vector2i(22, 6), Vector2i(14, 14), Vector2i(20, 14),
]
const POS_CARROS := [
	Vector2i(11, 4), Vector2i(13, 13), Vector2i(17, 14), Vector2i(7, 15),
]
const POS_BARCO := Vector2i(25, 12)

const LABIRINTO_ORIGEM := Vector2i(28, 1)
const LABIRINTO := [
	"#########",
	"#.....#.#",
	"#.###.#.#",
	"#.#...#.#",
	"#.#.###.#",
	"#.#.....#",
	"#.#######",
]


func _ready() -> void:
	var chao: TileMapLayer = get_node_or_null("Chão")
	var pista: TileMapLayer = get_node_or_null("Pista")
	var agua: TileMapLayer = get_node_or_null("Água")
	var decoracao: TileMapLayer = get_node_or_null("Decoração")
	if chao == null or pista == null or agua == null or decoracao == null:
		return

	for camada in [chao, pista, agua, decoracao]:
		if not camada.get_used_cells().is_empty():
			return

	var celulas_pista := _calcular_pista()
	var celulas_agua := _calcular_agua()
	var celulas_deco := _calcular_decoracao(celulas_pista, celulas_agua)

	for y in ALTURA:
		for x in LARGURA:
			chao.set_cell(Vector2i(x, y), FONTE, _tile_chao(x, y))

	for celula in celulas_pista:
		var mascara := 0
		if celulas_pista.has(celula + Vector2i.UP):
			mascara |= 1
		if celulas_pista.has(celula + Vector2i.RIGHT):
			mascara |= 2
		if celulas_pista.has(celula + Vector2i.DOWN):
			mascara |= 4
		if celulas_pista.has(celula + Vector2i.LEFT):
			mascara |= 8
		if mascara == 0:
			mascara = 10
		pista.set_cell(celula, FONTE, Vector2i(mascara - 1, 2))

	for celula in celulas_agua:
		agua.set_cell(celula, FONTE, _tile_agua(celula.x, celula.y))

	for celula in celulas_deco:
		decoracao.set_cell(celula, FONTE, celulas_deco[celula])


func _ruido(x: int, y: int, sal: int) -> int:
	var h := (x * 374761393 + y * 668265263 + sal * 2246822519) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return h ^ (h >> 16)


func _tile_chao(x: int, y: int) -> Vector2i:
	var n := _ruido(x, y, 1) % 100
	if n < 82:
		return GRAMA
	elif n < 89:
		return GRAMAS_ENFEITADAS[0]
	elif n < 95:
		return GRAMAS_ENFEITADAS[1]
	return GRAMAS_ENFEITADAS[2]


func _tile_agua(x: int, y: int) -> Vector2i:
	var n := _ruido(x, y, 2) % 100
	if n < 70:
		return AGUAS[0]
	elif n < 88:
		return AGUAS[1]
	return AGUAS[2]


func _arvore(x: int, y: int) -> Vector2i:
	return ARVORES[_ruido(x, y, 3) % ARVORES.size()]


func _calcular_pista() -> Dictionary:
	var celulas := {}
	for trecho in TRECHOS_PISTA:
		var de: Vector2i = trecho[0]
		var ate: Vector2i = trecho[1]
		var passo := Vector2i(signi(ate.x - de.x), signi(ate.y - de.y))
		var atual := de
		celulas[atual] = true
		while atual != ate:
			atual += passo
			celulas[atual] = true
	return celulas


func _calcular_agua() -> Dictionary:
	var celulas := {}
	for retangulo in AGUAS_RETANGULOS:
		for y in range(retangulo.position.y, retangulo.end.y):
			for x in range(retangulo.position.x, retangulo.end.x):
				celulas[Vector2i(x, y)] = true
	return celulas


func _zona_reservada(celula: Vector2i) -> bool:
	if absi(celula.x - INICIO.x) <= 2 and absi(celula.y - INICIO.y) <= 2:
		return true
	if Rect2i(27, 1, 10, 9).has_point(celula):
		return true
	return false


func _calcular_decoracao(pista: Dictionary, agua: Dictionary) -> Dictionary:
	var deco := {}

	for x in LARGURA:
		deco[Vector2i(x, 0)] = _arvore(x, 0)
		deco[Vector2i(x, ALTURA - 1)] = _arvore(x, ALTURA - 1)
	for y in ALTURA:
		deco[Vector2i(0, y)] = _arvore(0, y)
		deco[Vector2i(LARGURA - 1, y)] = _arvore(LARGURA - 1, y)

	for linha in LABIRINTO.size():
		var texto: String = LABIRINTO[linha]
		for coluna in texto.length():
			if texto[coluna] == "#":
				var pos_arvore := LABIRINTO_ORIGEM + Vector2i(coluna, linha)
				deco[pos_arvore] = _arvore(pos_arvore.x, pos_arvore.y)

	for pos_predio in POS_PREDIOS:
		deco[pos_predio] = PREDIOS[_ruido(pos_predio.x, pos_predio.y, 4) % PREDIOS.size()]
	for pos_carro in POS_CARROS:
		deco[pos_carro] = CARROS[_ruido(pos_carro.x, pos_carro.y, 6) % CARROS.size()]
	deco[POS_BARCO] = BARCO

	for y in range(1, ALTURA - 1):
		for x in range(1, LARGURA - 1):
			var celula := Vector2i(x, y)
			if deco.has(celula) or pista.has(celula) or agua.has(celula):
				continue
			if _zona_reservada(celula):
				continue
			if _ruido(x, y, 5) % 100 < 9:
				deco[celula] = _arvore(x, y)

	return deco
