extends PanelContainer
class_name BuildPanel

signal started_dragging_object(buildOption)
# Refs
onready var warehouseButtonContainer = $GridContainer/Warehouses
onready var warehouseButton = $GridContainer/Warehouses/ButtonContainer/Button
onready var warehouseAmountLabel = $GridContainer/Warehouses/AmountContainer/CenterContainer/Label
onready var routeButtonContainer = $GridContainer/Routes
onready var routeButton = $GridContainer/Routes/ButtonContainer/Button
onready var routeAmountLabel = $GridContainer/Routes/AmountContainer/CenterContainer/Label
onready var cartButtonContainer = $GridContainer/Carts
onready var cartButton = $GridContainer/Carts/ButtonContainer/Button
onready var cartAmountLabel = $GridContainer/Carts/AmountContainer/CenterContainer/Label

func _ready():
  Utils.connect_signal(warehouseButton, "button_down", self, "initiate_dragging_warehouse")

func get_container_by_type(buildOption) -> Node2D:
  match buildOption:
    GameplayEnums.BuildOption.WAREHOUSE:
      return warehouseButtonContainer
    GameplayEnums.BuildOption.ROUTE:
      return routeButtonContainer
    GameplayEnums.BuildOption.CART:
       return cartButtonContainer
  return null

func get_button_by_type(buildOption) -> Node2D:
  match buildOption:
    GameplayEnums.BuildOption.WAREHOUSE:
      return warehouseButton
    GameplayEnums.BuildOption.ROUTE:
      return routeButton
    GameplayEnums.BuildOption.CART:
        return cartButton
  return null

func get_amountlabel_by_type(buildOption) -> Node2D:
  match buildOption:
    GameplayEnums.BuildOption.WAREHOUSE:
      return warehouseAmountLabel
    GameplayEnums.BuildOption.ROUTE:
      return routeAmountLabel
    GameplayEnums.BuildOption.CART:
        return cartAmountLabel
  return null

func hide_build_option(buildOption) -> void:
  var container = get_container_by_type(buildOption)
  if container:
    container.visible = false
    
func show_build_option(buildOption) -> void:
  var container = get_container_by_type(buildOption)
  if container:
    container.visible = true

func set_build_option_amount(buildOption, amount) -> void:
  var button = get_button_by_type(buildOption)
  if button:
    if amount > 0 && button.disabled:
      button.disabled = false
      button.modulate.a = 1
    elif amount <= 0 && !button.disabled:
      button.disabled = true
      button.modulate.a = 0.25
  var amountLabel = get_amountlabel_by_type(buildOption)
  if amountLabel:
    amountLabel.text = "x" + str(amount)

# Stock should consist of a BuildOption as key coupled with a value: { BuildOption.CART: 1 }
func update_stock(stock) -> void:
  for buildOption in stock.keys():
    show_build_option(buildOption)
    set_build_option_amount(buildOption, stock[buildOption])

func initiate_dragging_warehouse() -> void:
  emit_signal("started_dragging_object", GameplayEnums.BuildOption.WAREHOUSE)
