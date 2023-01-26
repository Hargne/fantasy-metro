extends PanelContainer
class_name ActionPrompt

var isVisible = false
var transitionSpeed = 10

signal action_prompt_button_pressed(buttonName)

enum ButtonType { DELETE, MOVE, UPGRADE }

# Refs
onready var buttonContainer = $Node2D/HBoxContainer
onready var deleteButton = $Node2D/HBoxContainer/DELETE
onready var moveButton = $Node2D/HBoxContainer/MOVE
onready var upgradeButton = $Node2D/HBoxContainer/UPGRADE

func _ready():
  modulate.a = 0

func _process(delta):
  if isVisible:
    modulate.a = lerp(modulate.a, 1, transitionSpeed * delta)
  elif modulate.a > 0:
    modulate.a = lerp(modulate.a, 0, transitionSpeed * delta)

func display(inputPosition: Vector2, buttonTypesToShow: Array) -> void:
  if !isVisible:
    set_global_position(inputPosition)
    for type in buttonTypesToShow:
      for button in buttonContainer.get_children():
        if button.name.to_upper() == ButtonType.keys()[type]:
          button.visible = true
          button.disabled = false
        else:
          button.visible = false
          button.disabled = true
        rect_size = rect_min_size
    isVisible = true

func hide() -> void:
  if isVisible:
    isVisible = false
    for button in buttonContainer.get_children():
      button.disabled = true

func button_clicked(buttonName) -> void:
  emit_signal('action_prompt_button_pressed', buttonName)
