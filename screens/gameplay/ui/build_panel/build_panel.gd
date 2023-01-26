extends PanelContainer
class_name BuildPanel

signal started_dragging_object(buildOption)
signal on_selected_route(route)
# Refs
onready var leftContainer = $HBoxContainer/Left
onready var rightContainer = $HBoxContainer/Right
onready var routesButton = $HBoxContainer/Left/VBoxContainer2/ROUTE
onready var routeSelectorContainer = $HBoxContainer/Left/VBoxContainer2/RouteSelector
onready var buildMenuButton = $HBoxContainer/Left/VBoxContainer/BUILD
onready var buildMenuContainer = $HBoxContainer/Left/VBoxContainer/BuildOptions
onready var cartButton = $HBoxContainer/Left/VBoxContainer/BuildOptions/CART
onready var warehouseButton = $HBoxContainer/Left/VBoxContainer/BuildOptions/WAREHOUSE

var buildPanelButtonPrefab = preload("res://screens/gameplay/ui/build_panel/build_panel_button/build_panel_button.tscn")

enum SubMenu { NONE, ROUTE, BUILD }
var _currentSubmenu = SubMenu.NONE

func _ready():
  Utils.connect_signal(buildMenuButton.button, "button_down", self, "toggle_build_menu")
  Utils.connect_signal(routesButton.button, "button_down", self, "toggle_route_menu")
  Utils.connect_signal(warehouseButton.button, "button_down", self, "initiate_dragging_object", [GameplayEnums.BuildOption.WAREHOUSE])
  Utils.connect_signal(cartButton.button, "button_down", self, "initiate_dragging_object", [GameplayEnums.BuildOption.CART])
  buildMenuContainer.get_node("AnimationPlayer").play("panel_transition_init")
  routeSelectorContainer.get_node("AnimationPlayer").play("panel_transition_init")

func get_button_by_type(buildOptionType) -> BuildPanelButton:
  match buildOptionType:
    GameplayEnums.BuildOption.CART:
      return cartButton
    GameplayEnums.BuildOption.WAREHOUSE:
      return warehouseButton
  return null

func hide_build_option(buildOption) -> void:
  var stockButton = get_button_by_type(buildOption)
  if stockButton:
    stockButton.visible = false
    
func show_build_option(buildOption) -> void:
  var stockButton = get_button_by_type(buildOption)
  if stockButton:
    stockButton.visible = true

func set_build_option_amount(buildOption, amount) -> void:
  var btn = get_button_by_type(buildOption)
  if btn:
    btn.set_stock_amount(amount)

# Stock should consist of a BuildOption as key coupled with a value: { BuildOption.CART: 1 }
func update_stock(stock) -> void:
  for buildOption in stock.keys():
    show_build_option(buildOption)
    set_build_option_amount(buildOption, stock[buildOption])

func display_submenu(submenu) -> void:
  match submenu:
    SubMenu.BUILD:
      buildMenuContainer.get_node("AnimationPlayer").play("panel_transition_in")
      hide_submenu(SubMenu.ROUTE)
    SubMenu.ROUTE:
      routeSelectorContainer.get_node("AnimationPlayer").play("panel_transition_in")
      hide_submenu(SubMenu.BUILD)
  _currentSubmenu = submenu

func hide_submenu(submenu) -> void:
  if _currentSubmenu == submenu:
    match submenu:
      SubMenu.BUILD:
        buildMenuContainer.get_node("AnimationPlayer").play("panel_transition_out")
      SubMenu.ROUTE:
        routeSelectorContainer.get_node("AnimationPlayer").play("panel_transition_out")
    _currentSubmenu = SubMenu.NONE

func toggle_submenu(submenu) -> void:
  if _currentSubmenu == submenu:
    hide_submenu(submenu)
  else:
    display_submenu(submenu)

func toggle_build_menu() -> void:
  toggle_submenu(SubMenu.BUILD)

func toggle_route_menu() -> void:
  toggle_submenu(SubMenu.ROUTE)

func initiate_dragging_object(type) -> void:
  emit_signal("started_dragging_object", type)

func set_route_options(routes: Array) -> void:
  # Start by removing existing routes
  for c in routeSelectorContainer.get_children():
    if c is BuildPanelButton:
      c.queue_free()
  if routes && routes.size() > 0:
    for route in routes:
      var buildPanelButton = buildPanelButtonPrefab.instance()
      buildPanelButton.backgroundColor = route.color
      routeSelectorContainer.add_child(buildPanelButton)
      Utils.connect_signal(buildPanelButton.button, "button_down", self, "select_route", [route])
    select_route(routes[0])

func hide_route_option(route: Route) -> void:
  for c in routeSelectorContainer.get_children():
    if c is BuildPanelButton:
      if c.backgroundColor == route.color:
        c.visible = false
      else:
        c.visible = true

func select_route(route: Route) -> void:
  emit_signal("on_selected_route", route)
  routesButton.set_background_color(route.color)
  hide_route_option(route)
  hide_submenu(SubMenu.ROUTE)
