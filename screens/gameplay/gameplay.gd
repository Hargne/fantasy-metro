extends Node2D
class_name Gameplay

var rng = RandomNumberGenerator.new()
# Refs
onready var menu = $Menu
onready var mapNodeController: MapNodeController = $MapNodeController
onready var cartController: CartController = $CartController
onready var uiController: GameplayUIController = $UI

export var showMenuOnStartup = false
var isInteracting = false
var interactPosition: Vector2
var interactTarget: Node
var isDragging = false
var selectedObjects = []
var demandIncrementTimer: Timer
var secondsBetweenDemandIncrement = 20
var dragStartApproved = false

var typeOfObjectBeingPlaced

var buildStock = {
  GameplayEnums.BuildOption.WAREHOUSE: 1,
  GameplayEnums.BuildOption.ROUTE: 3,
  GameplayEnums.BuildOption.CART: 2,
}
var _defaultCollisionLayer = 2147483647

func _ready():
  rng.randomize()
  mapNodeController.rng = rng
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
      isDragging = false
      isInteracting = true
      interactPosition = get_global_mouse_position()
      interactTarget = get_object_at_cursor_location()
    elif event.is_action_released("interact"):
      if isDragging:
        on_interact_drag_end()
      else:
        on_interact_click_handler()
      isInteracting = false
      interactTarget = null
    elif event.is_action_pressed("pause_game"):
      pause_game()
      menu.display(true)

    if event is InputEventMouseMotion && isInteracting:
      if interactPosition && interactPosition.distance_to(get_global_mouse_position()) > 10 && !isDragging:
        isDragging = true
      elif isDragging:
        on_interact_drag()

func start_new_game() -> void:
  # Setup routes
  var amountOfRoutes = 2
  var _createdRoutes = []
  for i in amountOfRoutes:
    _createdRoutes.append(mapNodeController.create_route())
  uiController.buildPanel.set_route_options(_createdRoutes)

  var planetTypes = GameplayEnums.PlanetType.values()
  planetTypes.shuffle()

  for n in 3:
    mapNodeController.add_planet(planetTypes[n])

  planetTypes.shuffle()
  mapNodeController.add_planet(planetTypes[0])

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
  if interactTarget is Cart:
    cartController.blur_all_carts(interactTarget)
    interactTarget.cart_clicked()
    return
  else:
    cartController.blur_all_carts()

  var clickedConnection = mapNodeController.get_connection_from_point(interactPosition)
  if clickedConnection:
    mapNodeController.blur_all_connections(clickedConnection)
    selectedObjects.append(clickedConnection)
    clickedConnection.highlight(true)
  else:
    mapNodeController.blur_all_connections()

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
  var shouldHideUI = false
  # Placing Carts
  if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART && cartController.objectBeingPlaced:
    shouldHideUI = true
    cartController.objectBeingPlaced.position = mpos
    var connection = mapNodeController.get_connection_from_point(mpos)
    if connection && !connection.is_highlighted():
      connection.highlight()
      cartController.canPlaceObject = true			
    elif !connection && cartController.canPlaceObject:
      cartController.canPlaceObject = false
      mapNodeController.blur_all_connections()
  # Placing Objects
  elif mapNodeController.is_placing_new_object():
    shouldHideUI = true
    mapNodeController.objectBeingPlaced.position = mpos
    if mapNodeController.objectBeingPlaced is Area2D && mapNodeController.objectBeingPlaced.get_overlapping_areas().size() > 0:
        mapNodeController.canPlaceObject = false
  # Dragging Routes
  else:
    if !mapNodeController.is_dragging_new_connection() && interactTarget && interactTarget is MapNode && can_build_route():
      mapNodeController.start_dragging_new_route(interactTarget)
    elif mapNodeController.is_dragging_new_connection():
      mapNodeController.update_drag_new_route(mpos)
      if !shouldHideUI:
        shouldHideUI = true
  # Hide Build Panel while dragging
  if shouldHideUI && uiController.buildPanel.isVisible:
    uiController.buildPanel.hide()

func on_interact_drag_end() -> void:
  # Show Build Panel after a drag
  if !uiController.buildPanel.isVisible:
    uiController.buildPanel.display()

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
      if interactTarget && interactTarget is MapNode:
        mapNodeController.finish_drawing_new_route_nodes(mapNodeController.activeRoute)
      mapNodeController.hide_drag_new_connection()
    # Placing Objects
    elif mapNodeController.is_placing_new_object():
      mapNodeController.end_place_new_object()
      mapNodeController.blur_all_connections()
  # Finally reset drag variables
  isDragging = false
  interactTarget = null
  interactPosition = Vector2.ZERO
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
  if interactTarget is MapNode:
    var route = mapNodeController.activeRoute
    if route.connections.size() == 0:
      return true
    else:
      return route.get_all_connections_for_map_node(interactTarget).size() == 1 && route.get_number_of_open_nodes() == 2
  else:
    return false

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
  var newTravellerIsPossible = false
  var addedNewTraveller = false

  var planetNodes = mapNodeController.get_planet_nodes()
  var planetTypes = GameplayEnums.PlanetType.values()
  var alienTypes = GameplayEnums.Resource.values()

  if planetNodes.size() > 0:
    for planetNode in planetNodes:
      if planetNode.can_add_traveller():
        newTravellerIsPossible = true

        if rng.randi_range(0, 99) < 50: # for now, only adding 50% of the time per planet
          var foundValidAlienType = false

          while !foundValidAlienType:
            foundValidAlienType = true
            var pidx = rng.randi_range(0, planetTypes.size() - 1)
            
            var pt = planetTypes[pidx]

            if pt == planetNode.planetType || !mapNodeController.does_planet_type_exist(pt):
              foundValidAlienType = false

            if foundValidAlienType:
              var waitingTraveller = alienTypes[pidx]
              planetNode.add_traveller(waitingTraveller)
              addedNewTraveller = true

  # we keep trying until we get at least 1 passenger somewhere
  if newTravellerIsPossible && !addedNewTraveller:
    on_demand_increment_timer_timeout()
    return

  # Restart the timer
  start_demand_increment_timer(secondsBetweenDemandIncrement)
