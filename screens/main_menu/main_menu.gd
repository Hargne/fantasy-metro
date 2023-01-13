extends Node2D

var game_manager

func _ready():
  game_manager = get_node("/root/GameManager")

func start_game() -> void:
  # for now, let's assume we pressed level #1 button
  # this code is just testing out how we might set up the game from main menu
  game_manager.init_game(1, 1)  

  if get_tree().change_scene("res://screens/gameplay/gameplay.tscn") != OK:
    printerr("Could not start game")
