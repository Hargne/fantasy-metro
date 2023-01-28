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
  Utils.connect_signal(deleteButton.button, "pressed", self, "button_clicked", [ButtonType.DELETE])
  Utils.connect_signal(moveButton.button, "pressed", self, "button_clicked", [ButtonType.MOVE])
  Utils.connect_signal(upgradeButton.button, "pressed", self, "button_clicked", [ButtonType.UPGRADE])

func _process(delta):
  if isVisible:
    modulate.a = lerp(modulate.a, 1, transitionSpeed * delta)
  elif modulate.a > 0:
    modulate.a = lerp(modulate.a, 0, transitionSpeed * delta)

func display(inputPosition: Vector2, buttonTypesToShow: Array) -> void:
  if !isVisible:
    set_global_position(inputPosition)

    var enum_keys = []
    for type in buttonTypesToShow:
      enum_keys.append(ButtonType.keys()[type])

    for button in buttonContainer.get_children():
      var key = button.name.to_upper()
      if enum_keys.has(key):
        button.visible = true
        enable_button(ButtonType[key])
      else:
        button.visible = false
        disable_button(ButtonType[key])
      rect_size = rect_min_size
    isVisible = true

func hide() -> void:
  if isVisible:
    isVisible = false
    for button in buttonContainer.get_children():
      button.disable()

func button_clicked(buttonType) -> void:
  emit_signal('on_button_clicked', buttonType)

func get_button_by_type(buttonType) -> TextureButton:
  match buttonType:
    ButtonType.DELETE:
      return deleteButton
    ButtonType.MOVE:
      return moveButton
    ButtonType.UPGRADE:
      return upgradeButton
  return null

func disable_button(buttonType) -> void:
  var btn = get_button_by_type(buttonType)
  if btn:
    btn.disable()

func enable_button(buttonType) -> void:
  var btn = get_button_by_type(buttonType)
  if btn:
    btn.enable()
