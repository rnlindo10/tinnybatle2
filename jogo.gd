extends Node2D

@onready var jogador: CharacterBody2D = $Player
@onready var bandeira: Area2D = $Bandeira
@onready var caixa: Control = $Interface/Caixa

var terminou := false


func _ready() -> void:
	bandeira.body_entered.connect(_on_bandeira_body_entered)


func _on_bandeira_body_entered(corpo: Node2D) -> void:
	if corpo == jogador and not terminou:
		terminou = true
		jogador.set_physics_process(false)
		jogador.get_node("Animação").play("idle")
		caixa.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if terminou and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
