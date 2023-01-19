extends CanvasLayer
class_name GameplayUIController

onready var buildPanel: BuildPanel = $VBoxContainer/BuildPanel
onready var actionPrompt = $VBoxContainer/PlayArea/ActionPrompt

func display_action_prompt(inputPosition: Vector2) -> void:
  actionPrompt.set_global_position(inputPosition)
  actionPrompt.isVisible = true
