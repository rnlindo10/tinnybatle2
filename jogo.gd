extends Node2D

@onready var jogador: CharacterBody2D = $Player
@onready var alvo: Area2D = $Alvo
@onready var dica: Label = $Interface/Dica

var terminou := false


func _ready() -> void:
	alvo.body_entered.connect(_on_alvo_body_entered)


func _on_alvo_body_entered(corpo: Node2D) -> void:
	if corpo == jogador and not terminou:
		terminou = true
		jogador.set_physics_process(false)
		jogador.get_node("Animação").play("idle")
		dica.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if terminou and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
