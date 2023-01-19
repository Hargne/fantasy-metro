extends Node2D

var application_manager

func _ready():
  application_manager = get_node("/root/ApplicationManager")

func start_game() -> void:
  if get_tree().change_scene("res://screens/gameplay/gameplay.tscn") != OK:
    printerr("Could not start game")
