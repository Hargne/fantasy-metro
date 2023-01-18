extends PanelContainer
class_name BuildPanel

signal started_dragging_object(buildOption)
# Refs
onready var warehouseButtonContainer = $GridContainer/Warehouses
onready var warehouseButton = $GridContainer/Warehouses/Button
onready var routeButtonContainer = $GridContainer/Routes
onready var routeButton = $GridContainer/Routes/Button
onready var cartButtonContainer = $GridContainer/Carts
onready var cartButton = $GridContainer/Carts/Button

func _ready():
  Utils.connect_signal(warehouseButton, "button_down", self, "initiate_dragging_warehouse")

func get_buttoncontainer_by_type(buildOption) -> Node2D:
  match buildOption:
    GameplayEnums.BuildOption.WAREHOUSE:
      return warehouseButtonContainer
    GameplayEnums.BuildOption.ROUTE:
      return routeButtonContainer
    GameplayEnums.BuildOption.CART:
       return cartButtonContainer
  return null

func hide_build_option(buildOption) -> void:
  var buttonContainer = get_buttoncontainer_by_type(buildOption)
  if buttonContainer:
    buttonContainer.visible = false
    
func show_build_option(buildOption) -> void:
  var buttonContainer = get_buttoncontainer_by_type(buildOption)
  if buttonContainer:
    buttonContainer.visible = true

func set_build_option_amount(buildOption, amount) -> void:
  var buttonContainer = get_buttoncontainer_by_type(buildOption)
  if buttonContainer:
    for c in buttonContainer.get_children():
      if c is Label:
        c.text = "x" + str(amount)
      elif c is TextureButton:
        if amount > 0 && c.disabled:
          c.disabled = false
          c.modulate.a = 1
        elif amount <= 0 && !c.disabled:
          c.disabled = true
          c.modulate.a = 0.25

# Stock should consist of a BuildOption as key coupled with a value: { BuildOption.CART: 1 }
func update_stock(stock) -> void:
  for buildOption in stock.keys():
    show_build_option(buildOption)
    set_build_option_amount(buildOption, stock[buildOption])

func initiate_dragging_warehouse() -> void:
  emit_signal("started_dragging_object", GameplayEnums.BuildOption.WAREHOUSE)
