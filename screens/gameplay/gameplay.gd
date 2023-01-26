extends Node2D
class_name Gameplay

var rng = RandomNumberGenerator.new()
# Refs
onready var menu = $Menu
onready var mapNodeController: MapNodeController = $MapNodeController
onready var cartController: CartController = $CartController
onready var uiController: GameplayUIController = $UI
onready var map: Map = $Map

export var showMenuOnStartup = false
var isInteractBeingHeldDown = false
var interactDuration = 0
var interactHoldDownThreshold = 15
var interactPosition: Vector2
var interactTarget: Node
var selectedObjects = []
var demandIncrementTimer: Timer
var secondsBetweenDemandIncrement = 20

var typeOfObjectBeingPlaced

var buildStock = {
  GameplayEnums.BuildOption.WAREHOUSE: 1,
  GameplayEnums.BuildOption.ROUTE: 3,
  GameplayEnums.BuildOption.CART: 2,
}
var _defaultCollisionLayer = 2147483647

func _ready():
  rng.randomize()
  setup_demand_increment_timer()
  # Connect Build Panel
  Utils.connect_signal(uiController.buildPanel, "started_dragging_object", self, "on_new_object_drag_start")
  Utils.connect_signal(uiController.buildPanel, "on_selected_route", mapNodeController, "set_active_route")
  # Connect Map Node Controller events
  Utils.connect_signal(mapNodeController, "on_increase_stock", self, "increase_stock_item")
  Utils.connect_signal(mapNodeController, "on_decrease_stock", self, "decrease_stock_item")
  Utils.connect_signal(cartController, "on_increase_stock", self, "increase_stock_item")
  Utils.connect_signal(cartController, "on_decrease_stock", self, "decrease_stock_item")  
  # Allow for nodes to get initialized
  yield(get_tree().create_timer(0.1), "timeout")
  uiController.buildPanel.update_stock(buildStock)
  # Menu
  Utils.connect_signal(menu, "on_start_game_pressed", self, "start_new_game")
  Utils.connect_signal(menu, "on_continue_game_pressed", self, "unpause_game")
  if showMenuOnStartup:
    pause_game()
    menu.display(false)
  else:
    start_new_game()

func _input(event):
  if !menu.visible:
    if event.is_action_pressed("interact"):
      isInteractBeingHeldDown = true
      interactDuration = 0
      interactPosition = get_global_mouse_position()
      interactTarget = get_object_at_cursor_location()
    elif event.is_action_released("interact"):
      isInteractBeingHeldDown = false
      if interactDuration < interactHoldDownThreshold:
        on_interact_click_handler()
      else:
        on_interact_drag_end()
      interactDuration = 0
      interactTarget = null
    elif event.is_action_pressed("pause_game"):
      pause_game()
      menu.display(true)

func _process(_delta):
  if isInteractBeingHeldDown && interactDuration < interactHoldDownThreshold:
    interactDuration += 1
  elif isInteractBeingHeldDown:
    on_interact_drag()

func start_new_game() -> void:
  # Setup routes
  var created_routes = []
  for i in 2:
    created_routes.append(mapNodeController.create_route())
  uiController.buildPanel.set_route_options(created_routes)
  # Unpause and start
  unpause_game()
  menu.hide()

func pause_game() -> void:
  get_tree().paused = true

func unpause_game() -> void:
  menu.hide()
  get_tree().paused = false

#
# Interaction Handlers
#

func get_object_at_cursor_location() -> Node:
  var collision_objects = get_world_2d().direct_space_state.intersect_point(get_global_mouse_position(), 1, [], _defaultCollisionLayer, true, true)
  if collision_objects:
    return collision_objects[0].collider
  return null

func on_interact_click_handler() -> void:
  cartController.end_place_new_object(null)
  mapNodeController.canPlaceObject = null
  mapNodeController.end_place_new_object()

  if interactTarget is Cart:
    cartController.blur_all_carts(interactTarget)
    interactTarget.cart_clicked()
    return
  else:
    cartController.blur_all_carts()
  
  var clickedConnection = mapNodeController.get_connection_from_point(interactPosition)
  if clickedConnection != null:
    mapNodeController.blur_all_connections(clickedConnection)
    if clickedConnection:
      selectedObjects.append(clickedConnection)
      clickedConnection.highlight(true)

# Gets called when the player starts dragging an object from the build panel
func on_new_object_drag_start(objectToBeSpawned) -> void:
  cartController.blur_all_carts()
  
  # Check if there's enough in stock
  if buildStock[objectToBeSpawned] > 0:
    typeOfObjectBeingPlaced = objectToBeSpawned
    if objectToBeSpawned == GameplayEnums.BuildOption.CART:
      cartController.initiate_place_new_object(objectToBeSpawned, get_global_mouse_position())
    else:
      mapNodeController.initiate_place_new_object(objectToBeSpawned, get_global_mouse_position())      

func on_interact_drag() -> void:
  var mpos = get_global_mouse_position()

  # Carts
  if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
    cartController.objectBeingPlaced.position = mpos
    var connection = mapNodeController.get_connection_from_point(mpos)
    if connection:      
      mapNodeController.blur_all_connections(connection)
      connection.highlight()
      cartController.canPlaceObject = true			
    else:
      cartController.canPlaceObject = false
      mapNodeController.blur_all_connections()			
  else:
    # Routes
    if can_build_route() && !mapNodeController.is_placing_new_object() && interactTarget && interactTarget is MapNode:
      mapNodeController.update_drag_new_connection_points(interactTarget.get_connection_point(), mpos)
    # Other Objects
    elif mapNodeController.is_placing_new_object():
      mapNodeController.objectBeingPlaced.position = map.get_tile_position_in_world(mpos)
      mapNodeController.canPlaceObject = map.is_tile_buildable(mpos)
      if mapNodeController.canPlaceObject && mapNodeController.objectBeingPlaced is Area2D && mapNodeController.objectBeingPlaced.get_overlapping_areas().size() > 0:
          mapNodeController.canPlaceObject = false

func on_interact_drag_end() -> void:
  if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
    var connection = mapNodeController.get_connection_from_point(cartController.objectBeingPlaced.position)		
    if connection:
      if cartController.end_place_new_object(connection):
        decrease_stock_item(GameplayEnums.BuildOption.CART)
    else:    
      cartController.end_place_new_object(null)      
    mapNodeController.blur_all_connections()
  else:
    # Routes
    if mapNodeController.is_dragging_new_connection():
      var objectAtEndOfDrag = get_object_at_cursor_location()
      if interactTarget && interactTarget is MapNode && objectAtEndOfDrag && objectAtEndOfDrag is MapNode && interactTarget != objectAtEndOfDrag && can_build_route():
        mapNodeController.connect_map_nodes(interactTarget, objectAtEndOfDrag, mapNodeController.activeRoute)
      mapNodeController.hide_drag_new_connection()
    # Placing Objects
    elif mapNodeController.is_placing_new_object():
      mapNodeController.end_place_new_object()
      mapNodeController.blur_all_connections()
    
  interactTarget = null
  typeOfObjectBeingPlaced = null

func deselect_objects() -> void:
  for obj in selectedObjects:
    if obj.has_method("blur"):
      obj.blur()
  selectedObjects.clear()

#
# Stock
#

func increase_stock_item(item, amount = 1) -> void:
  buildStock[item] += amount
  uiController.buildPanel.set_build_option_amount(item, buildStock[item])

func decrease_stock_item(item, amount = 1) -> void:
  buildStock[item] -= amount
  uiController.buildPanel.set_build_option_amount(item, buildStock[item])

func can_build_route() -> bool:
  return buildStock[GameplayEnums.BuildOption.ROUTE] > 0

#
# Demand Increment Timer
#

func setup_demand_increment_timer() -> void:
  if demandIncrementTimer != null:
    return
  demandIncrementTimer = Timer.new()
  add_child(demandIncrementTimer)
  demandIncrementTimer.name = "DemandIncrementTimer"
  Utils.connect_signal(demandIncrementTimer, "timeout", self, "on_demand_increment_timer_timeout")
  start_demand_increment_timer(2)

func start_demand_increment_timer(time: int) -> void:
  demandIncrementTimer.wait_time = time
  demandIncrementTimer.start()
  
func on_demand_increment_timer_timeout() -> void:
  var villageNodes = mapNodeController.get_village_nodes()
  if villageNodes.size() > 0:
    for villageNode in villageNodes:
      if villageNode.can_add_resource_demand():
        var demandedResource = GameplayEnums.Resource.values()[rng.randi() % GameplayEnums.Resource.size()]
        villageNode.add_resource_demand(demandedResource)
  # Restart the timer
  start_demand_increment_timer(secondsBetweenDemandIncrement)
