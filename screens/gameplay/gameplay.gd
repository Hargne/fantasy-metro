extends Node2D
class_name Gameplay

var rng = RandomNumberGenerator.new()
# Refs
onready var mapNodeController: MapNodeController = $MapNodeController
onready var uiController: GameplayUIController = $UI
onready var map: Map = $Map

var isInteractBeingHeldDown = false
var interactDuration = 0
var interactHoldDownThreshold = 15
var interactPosition: Vector2
var interactTarget: Node
var selectedObjects = []
var demandIncrementTimer: Timer
var secondsBetweenDemandIncrement = 20

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
  # Connect Map Node Controller events
  Utils.connect_signal(mapNodeController, "on_increase_stock", self, "increase_stock_item")
  Utils.connect_signal(mapNodeController, "on_decrease_stock", self, "decrease_stock_item")
  # Allow for nodes to get initialized
  yield(get_tree().create_timer(0.1), "timeout")
  uiController.buildPanel.update_stock(buildStock)

func _input(event):
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

func _process(_delta):
  if isInteractBeingHeldDown && interactDuration < interactHoldDownThreshold:
    interactDuration += 1
  elif isInteractBeingHeldDown:
    on_interact_drag()

#
# Interaction Handlers
#

func get_object_at_cursor_location() -> Node:
  var collision_objects = get_world_2d().direct_space_state.intersect_point(get_global_mouse_position(), 1, [], _defaultCollisionLayer, true, true)
  if collision_objects:
    return collision_objects[0].collider
  return null

func on_interact_click_handler() -> void:
  var clickedRoute = mapNodeController.get_route_from_point(interactPosition)
  if clickedRoute:
    selectedObjects.append(clickedRoute)
    clickedRoute.highlight()

func on_interact_drag() -> void:
  var mpos = get_global_mouse_position()

  # Routes
  if interactTarget && interactTarget is MapNode && can_build_route() && !mapNodeController.is_placing_new_object():
    mapNodeController.update_drag_new_route_points(interactTarget.get_connection_point(), mpos)
  elif mapNodeController.is_placing_new_object():
    if mapNodeController.typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
      mapNodeController.objectBeingPlaced.position = mpos
      var route = mapNodeController.get_route_from_point(mpos)
      if route:
        route.highlight()
        mapNodeController.canPlaceObject = true
      else:
        mapNodeController.canPlaceObject = false
        mapNodeController.blur_all_routes()
    else:
      mapNodeController.objectBeingPlaced.position = map.get_tile_position_in_world(mpos)
      mapNodeController.canPlaceObject = map.is_tile_buildable(mpos)
      if mapNodeController.canPlaceObject && mapNodeController.objectBeingPlaced is Area2D && mapNodeController.objectBeingPlaced.get_overlapping_areas().size() > 0:
        mapNodeController.canPlaceObject = false

func on_interact_drag_end() -> void:
  # Routes
  if mapNodeController.is_dragging_new_route():
    var objectAtEndOfDrag = get_object_at_cursor_location()
    if interactTarget && interactTarget is MapNode && objectAtEndOfDrag && objectAtEndOfDrag is MapNode && interactTarget != objectAtEndOfDrag && can_build_route():
      mapNodeController.connect_map_nodes(interactTarget, objectAtEndOfDrag)
    mapNodeController.hide_drag_new_route()
  # Placing Objects
  elif mapNodeController.is_placing_new_object():
    mapNodeController.end_place_new_object()
    mapNodeController.blur_all_routes()
  interactTarget = null

# Gets called when the player starts dragging an object from the build panel
func on_new_object_drag_start(objectToBeSpawned) -> void:
  # Check if there's enough in stock
  if buildStock[objectToBeSpawned] > 0:
    mapNodeController.initiate_place_new_object(objectToBeSpawned, get_global_mouse_position())

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
