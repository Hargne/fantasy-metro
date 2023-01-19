extends PanelContainer
class_name BuildPanel

signal started_dragging_object(buildOption)
# Refs
onready var leftContainer = $HBoxContainer/Left
onready var rightContainer = $HBoxContainer/Right

func _ready():
  Utils.connect_signal(get_stockbutton_by_type(GameplayEnums.BuildOption.WAREHOUSE).button, "button_down", self, "initiate_dragging_warehouse")

func get_stockbutton_by_type(buildOptionType) -> StockButton:
  for container in [leftContainer, rightContainer]:
    for c in container.get_children():
      if c.name.to_upper() == GameplayEnums.BuildOption.keys()[buildOptionType]:
        return c
  return null

func hide_build_option(buildOption) -> void:
  var stockButton = get_stockbutton_by_type(buildOption)
  if stockButton:
    stockButton.visible = false
    
func show_build_option(buildOption) -> void:
  var stockButton = get_stockbutton_by_type(buildOption)
  if stockButton:
    stockButton.visible = true

func set_build_option_amount(buildOption, amount) -> void:
  var btn = get_stockbutton_by_type(buildOption)
  if btn:
    btn.set_stock_amount(amount)

# Stock should consist of a BuildOption as key coupled with a value: { BuildOption.CART: 1 }
func update_stock(stock) -> void:
  for buildOption in stock.keys():
    show_build_option(buildOption)
    set_build_option_amount(buildOption, stock[buildOption])

func initiate_dragging_warehouse() -> void:
  emit_signal("started_dragging_object", GameplayEnums.BuildOption.WAREHOUSE)
