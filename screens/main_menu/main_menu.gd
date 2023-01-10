extends Node2D

func start_game() -> void:
  if !get_tree().change_scene("res://screens/gameplay/gameplay.tscn"):
    printerr("Could not start game")
