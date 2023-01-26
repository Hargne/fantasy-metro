extends Control
class_name BuildPanelButton

export var backgroundColor: Color = Color("#666666")
export var icon: Texture
export var tooltiptext = ""
export var showAmount = false
var _currentAmount = 0

# Refs
onready var background = $PanelContainer/TextureRect
onready var button = $PanelContainer/Button
onready var amountLabel = $Amount
onready var animations = $AnimationPlayer
onready var tooltip = $Tooltip

func _ready():
  button.icon = icon
  Utils.connect_signal(button, "mouse_entered", self, "display_tooltip")
  Utils.connect_signal(button, "mouse_exited", self, "hide_tooltip")
  tooltip.text = tooltiptext
  hide_tooltip()
  if !showAmount:
    amountLabel.visible = false
  set_background_color(backgroundColor)

func set_stock_amount(amount: int) -> void:
  amountLabel.text = "x" + str(amount)
  if amount <= 0:
    button.disabled = true
  elif button.disabled:
    button.disabled = false
  # Animation
  if _currentAmount != amount:
    animations.playback_speed = 2
    animations.play("amount_changed")
  _currentAmount = amount

func display_tooltip() -> void:
  if tooltiptext.length() > 0:
    tooltip.visible = true
    tooltip.rect_position = Vector2((button.rect_size.x - tooltip.rect_size.x) / 2, - 50)

func hide_tooltip() -> void:
  tooltip.visible = false

func set_background_color(color: Color) -> void:
  backgroundColor = color
  background.modulate = color
