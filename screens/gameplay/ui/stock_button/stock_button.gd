extends Control
class_name StockButton

export var buttonIcon: Texture
export var displayOnly = false
var buttonColor = Color("#222222")
var amountBoxColor = Color("#111111")
var amountLabelColor = Color("#ffffff")
var _currentAmount = 0

# Refs
onready var button = $Button
onready var displayOnlyIcon = $TextureRect
onready var amountContainer = $AmountContainer
onready var amountLabel = $AmountContainer/Label
onready var animations = $AnimationPlayer

func _ready():
  if displayOnly:
    button.visible = false
    displayOnlyIcon.visible = true
    displayOnlyIcon.texture = buttonIcon
  else:
    button.visible = true
    button.icon = buttonIcon
    displayOnlyIcon.visible = false
  amountContainer.get("custom_styles/panel/StyleBoxFlat").bg_color = amountBoxColor
  amountLabel.modulate = amountLabelColor

func set_stock_amount(amount: int) -> void:
  amountLabel.text = "x" + str(amount)
  if amount <= 0:
    button.disabled = true
    button.modulate.a = 0.25
    displayOnlyIcon.modulate.a = 0.25
  elif button.disabled:
    button.disabled = false
    button.modulate.a = 1
    displayOnlyIcon.modulate.a = 1
  # Animation
  if _currentAmount != amount:
    animations.playback_speed = 2
    animations.play("amount_changed")
  _currentAmount = amount
