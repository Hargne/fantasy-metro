extends PanelContainer
class_name ActionPrompt

var isVisible = false
var transitionSpeed = 10

signal on_button_clicked(buttonName)

enum ButtonType { DELETE, MOVE, UPGRADE }

# Refs
onready var buttonContainer = $HBoxContainer
onready var deleteButton = $HBoxContainer/DELETE
onready var moveButton = $HBoxContainer/MOVE
onready var upgradeButton = $HBoxContainer/UPGRADE

func _ready():
  modulate.a = 0
  Utils.connect_signal(deleteButton, "pressed", self, "button_clicked", [ButtonType.DELETE])
  Utils.connect_signal(moveButton, "pressed", self, "button_clicked", [ButtonType.MOVE])
  Utils.connect_signal(upgradeButton, "pressed", self, "button_clicked", [ButtonType.UPGRADE])

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

func button_clicked(buttonType) -> void:
  emit_signal('on_button_clicked', buttonType)
