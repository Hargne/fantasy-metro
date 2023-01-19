extends PanelContainer
class_name ActionPrompt

var isVisible = false
var transitionSpeed = 10

enum ButtonType { DELETE, MOVE, UPGRADE }

# Refs
onready var buttonContainer = $HBoxContainer
onready var deleteButton = $HBoxContainer/DELETE
onready var moveButton = $HBoxContainer/MOVE
onready var upgradeButton = $HBoxContainer/UPGRADE

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
        button.visible = button.name.to_upper() == ButtonType.keys()[type]
        rect_size = rect_min_size
    isVisible = true

func hide() -> void:
  if isVisible:
    isVisible = false
