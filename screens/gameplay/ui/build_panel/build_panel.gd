extends PanelContainer
class_name BuildPanel

signal started_dragging_object(buildOption)
signal on_selected_route(route)
# Refs
onready var leftContainer = $HBoxContainer/Left
onready var rightContainer = $HBoxContainer/Right
onready var routesButton = $HBoxContainer/Left/VBoxContainer2/ROUTE
onready var routeList: PopupList = $HBoxContainer/Left/VBoxContainer2/RouteSelector
onready var buildMenuButton = $HBoxContainer/Left/VBoxContainer/BUILD
onready var buildList: PopupList = $HBoxContainer/Left/VBoxContainer/BuildOptions
onready var cartButton = $HBoxContainer/Left/VBoxContainer/BuildOptions/CART
onready var warehouseButton = $HBoxContainer/Left/VBoxContainer/BuildOptions/WAREHOUSE

var panelButtonPrefab = preload("res://screens/gameplay/ui/panel_button/panel_button.tscn")
# Sub Menus
enum SubMenu { NONE, ROUTE, BUILD }
var _currentSubmenu = SubMenu.NONE
# Transitions
var isVisible = true
var transitionSpeed = 8

func _ready():
  Utils.connect_signal(buildMenuButton.button, "button_down", self, "toggle_submenu", [SubMenu.BUILD])
  Utils.connect_signal(routesButton.button, "button_down", self, "toggle_submenu", [SubMenu.ROUTE])
  Utils.connect_signal(warehouseButton.button, "button_down", self, "initiate_dragging_object", [GameplayEnums.BuildOption.WAREHOUSE])
  Utils.connect_signal(cartButton.button, "button_down", self, "initiate_dragging_object", [GameplayEnums.BuildOption.CART])

func _process(delta):
  transition_handler(delta)

func transition_handler(delta: float) -> void:
  if isVisible && modulate.a < 1:
    modulate.a = lerp(modulate.a, 1, transitionSpeed * delta)
  elif !isVisible && modulate.a > 0:
    modulate.a = lerp(modulate.a, 0, transitionSpeed * delta)

func hide() -> void:
  isVisible = false

func display() -> void:
  isVisible = true

func get_button_by_type(buildOptionType) -> PanelButton:
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
      buildList.display()
      hide_submenu(SubMenu.ROUTE)
    SubMenu.ROUTE:
      routeList.display()
      hide_submenu(SubMenu.BUILD)
  _currentSubmenu = submenu

func hide_submenu(submenu, instant = false) -> void:
  if _currentSubmenu == submenu:
    match submenu:
      SubMenu.BUILD:
        buildList.hide(instant)
      SubMenu.ROUTE:
        routeList.hide(instant)
    _currentSubmenu = SubMenu.NONE

func toggle_submenu(submenu) -> void:
  if _currentSubmenu == submenu:
    hide_submenu(submenu)
  else:
    display_submenu(submenu)

func hide_all_submenus() -> void:
  hide_submenu(SubMenu.BUILD)
  hide_submenu(SubMenu.ROUTE)

func initiate_dragging_object(type) -> void:
  emit_signal("started_dragging_object", type)

func set_route_options(routes: Array) -> void:
  # Start by removing existing routes
  for c in routeList.get_children():
    if c is PanelButton:
      c.queue_free()
  if routes && routes.size() > 0:
    for route in routes:
      var panelButton = panelButtonPrefab.instance()
      routeList.add_child(panelButton)
      panelButton.set_background_color(route.color)
      Utils.connect_signal(panelButton.button, "button_down", self, "select_route", [route])
    select_route(routes[0])

func hide_route_option(route: Route) -> void:
  for c in routeList.get_children():
    if c is PanelButton:
      if c.backgroundColor == route.color:
        c.visible = false
      else:
        c.visible = true

func select_route(route: Route) -> void:
  emit_signal("on_selected_route", route)
  hide_submenu(SubMenu.ROUTE, true)
  hide_route_option(route)
  routesButton.set_background_color(route.color)
  routesButton.pop()
