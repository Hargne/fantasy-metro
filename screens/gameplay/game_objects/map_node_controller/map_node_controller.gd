extends Node2D
class_name MapNodeController

var rng
var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")
var planetNodePrefab = preload("res://screens/gameplay/game_objects/map_node/planet_node/planet_node.tscn")
var Route = load("res://screens/gameplay/game_objects/route/route.class.gd")
# Connections / Routes
var planets = []


var routes = []
var activeRoute: Route
var routeColors: Array = [
  Color("#C17A7A"),
  Color("#80A3D8"),
  Color("#599772"),
  Color("#9B58A0"),
  Color("#A3A3A3"),
  Color("#F0F7A2")
]
var defaultRouteColor = Color("#222222")

var connectionContainer: Node2D
var newRouteConnectionContainer: Node2D
var connectionPrefab = preload("res://screens/gameplay/game_objects/route/connection.tscn")
var dragNewConnectionVisual: Line2D

# SFX
onready var placeBuildingSFX = $PlaceBuildingSFX
onready var demolishRouteSFX = $DemolishSFX

signal on_increase_stock(item, amount)
signal on_decrease_stock(item, amount)

var newRoutePoints = []

func _ready():
  # Create a container for routes
  connectionContainer = Node2D.new()
  add_child(connectionContainer)
  move_child(connectionContainer, 0)

  newRouteConnectionContainer = Node2D.new()
  add_child(newRouteConnectionContainer)
  move_child(newRouteConnectionContainer, 0)
  newRouteConnectionContainer.hide()

func _process(_delta):
  if objectBeingPlaced:
    if canPlaceObject && objectBeingPlaced.modulate.a == 0.5:
      objectBeingPlaced.modulate.a = 1
    elif !canPlaceObject && objectBeingPlaced.modulate.a == 1:
      objectBeingPlaced.modulate.a = 0.5

#################################################################
# PLANETS
#################################################################      

func add_planet(planetType, x: float = -1, y: float = -1) -> PlanetNode:
  var planet = planetNodePrefab.instance()
  planet.planetType = planetType
  var sprite: Sprite = planet.get_node('Sprite')
  sprite.texture = load("res://screens/gameplay/game_objects/map_node/assets/" + planet.get_texture_for_planet_type())

  add_child(planet)
  planets.append(planet)

  var randomPosition = x == -1 && y == -1

  #TODO: MAKE POSITION DECISION SMART
  var valid = false
  while !valid:
    valid = true  

    if randomPosition:
      var pos = Vector2(rng.randi_range(-200, 200), rng.randi_range(-75, 75))    

      for existingPlanet in planets:
        var dist = pos.distance_to(existingPlanet.position)
        if dist < 75:
          valid = false

      if valid:
        planet.position = pos
        break   
    else:   
      planet.position = Vector2(x, y)
  
  return planet  

func get_planet_nodes() -> Array:
  var nodes = []
  for child in get_children():
    if child is PlanetNode:
      nodes.append(child)
  return nodes

func does_planet_type_exist(planetType) -> bool:
  for child in get_children():
    if child is PlanetNode:
      if child.planetType == planetType:
        return true
  return false

func get_village_nodes() -> Array:
  var nodes = []
  for child in get_children():
    if child is VillageNode:
      nodes.append(child)
  return nodes

func get_resource_nodes() -> Array:
  var nodes = []
  for child in get_children():
    if child is ResourceNode:
      nodes.append(child)
  return nodes

func get_warehouse_nodes() -> Array:
  var nodes = []
  for child in get_children():
    if child is WarehouseNode:
      nodes.append(child)
  return nodes  

func get_map_nodes() -> Array:
  var nodes = []

  for child in get_children():
    if child is PlanetNode:
      nodes.append(child)
  return nodes  

func get_map_node_from_point(point) -> MapNode:
  var nodes = get_map_nodes()

  for nd in nodes:
    if nd.get_connection_point() == point:
      return nd
  return null 

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.WAREHOUSE:
      objectBeingPlaced = warehouseNodePrefab.instance()
      add_child(objectBeingPlaced)
  if objectBeingPlaced:   
    objectBeingPlaced.position = startPosition   
    

func end_place_new_object() -> void:
  if canPlaceObject:
    if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.WAREHOUSE:
      var conn = get_connection_from_point(get_global_mouse_position())      
      if conn != null:
        # we are going to split the connection into 2
        activeRoute.connections.append(spawn_connection(conn.get_start_node(), objectBeingPlaced, activeRoute))
        activeRoute.connections.append(spawn_connection(conn.get_end_node(), objectBeingPlaced, activeRoute))
        conn.queue_free()
        activeRoute.connections.erase(conn) 

    emit_signal("on_decrease_stock", typeOfObjectBeingPlaced)
    placeBuildingSFX.play()
  else:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
  stop_placing_object()

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null
  newRouteConnectionContainer.hide()

func is_placing_new_object() -> bool:
  return objectBeingPlaced != null && is_instance_valid(objectBeingPlaced)

#################################################################
# Connections / Routes
#################################################################

# creates a new route that the player can use; all routes start EMPTY; the UI can then display the routes on the right
# side of the screen for the user to select
func create_route() -> Route:
  var route = Route.new()
  route.routeIndex = routes.size()
  route.color = routeColors[route.routeIndex]
  routes.append(route)  
  return route

func get_connection_by_map_nodes(node1: MapNode, node2: MapNode, route: Route = null) -> Connection:
  for rte in routes:
    if route == null || rte == route:
      for connection in rte.connections:
        if connection.mapNodes.has(node1) && connection.mapNodes.has(node2):
          return connection
  return null  

func set_active_route(newActiveRoute: Route) -> void:
  activeRoute = newActiveRoute
  for route in routes:
    for connection in route.connections:
      connection.change_color(routeColors[route.routeIndex] if newActiveRoute == route else defaultRouteColor)

func are_nodes_connected(node1: MapNode, node2: MapNode, route: Route) -> bool:
  return get_connection_by_map_nodes(node1, node2, route) != null

func finish_drawing_new_route_nodes(route: Route) -> void:
  if newRoutePoints.size() < 2:
    return

  for i in newRoutePoints.size() - 1:
    var pt1 = newRoutePoints[i]
    var pt2 = newRoutePoints[i + 1]
    var nd1 = get_map_node_from_point(pt1)
    var nd2 = get_map_node_from_point(pt2)

    if !are_nodes_connected(nd1, nd2, route):
      var connection = spawn_connection(nd1, nd2, route)
      route.connections.append(connection)

  newRoutePoints.clear()
  newRouteConnectionContainer.hide()

func spawn_connection(from: MapNode, to: MapNode, route: Route) -> Connection:
  var connection = connectionPrefab.instance()
  connection.route = route
  connection.connectionID = ApplicationManager.connectionID
  ApplicationManager.connectionID += 1
  connection.mapNodes = [from, to]
  connection.segments = [from.get_connection_point(), to.get_connection_point()]
  connection.width = 2
  connection.lineColor = routeColors[route.routeIndex]
  connectionContainer.add_child(connection)

  if ApplicationManager.showConnectionIDs:
    var lbl: Label = Label.new()
    lbl.set_position(connection.get_center_point())
    lbl.text = str(connection.connectionID)
    connection.add_child(lbl)

  Utils.connect_signal(connection, "on_demolish", self, "demolish_connection")
  return connection  

func demolish_connection(connection: Connection) -> void:
  delete_connection(connection)  
  demolishRouteSFX.play()

func delete_connection(connection: Connection) -> void:
  if is_instance_valid(connection):
    connection.queue_free()
    for route in routes:
      route.connections.erase(connection)

func get_connection_from_point(point: Vector2, useActiveRouteOnly: bool = true) -> Connection:
  var matchedConnections = []
  for route in routes:
    if route == activeRoute || !useActiveRouteOnly:
      for connection in route.connections:
        var startPoint = connection.get_start_point()
        var endPoint = connection.get_end_point()
        var closestLinePoint = Geometry.get_closest_point_to_segment_2d(point, startPoint, endPoint)
        var dist = point.distance_to(closestLinePoint)        

        if dist < 25:
          matchedConnections.append(connection)

  if matchedConnections.size() > 1:
    var closestDist = 9999999
    var closestConnection = null

    for connection in matchedConnections:
      var startPoint = connection.get_start_point()
      var endPoint = connection.get_end_point()
      var closestLinePoint = Geometry.get_closest_point_to_segment_2d(point, startPoint, endPoint)
      var dist = point.distance_to(closestLinePoint)
      if dist < closestDist:
        closestDist = dist
        closestConnection = connection

    return closestConnection
  elif matchedConnections.size() == 1:
    return matchedConnections[0]
  else:
    return null

func start_dragging_new_route(startNode: MapNode) -> void:
  var startPoint = startNode.get_connection_point()
  # Initiate visuals for when dragging a new route
  if !dragNewConnectionVisual:
    dragNewConnectionVisual = Line2D.new()
    dragNewConnectionVisual.width = 1.5
    dragNewConnectionVisual.default_color = activeRoute.color
    dragNewConnectionVisual.antialiased = true
    dragNewConnectionVisual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    dragNewConnectionVisual.end_cap_mode = Line2D.LINE_CAP_ROUND 
    newRouteConnectionContainer.add_child(dragNewConnectionVisual) 
  if dragNewConnectionVisual.default_color != activeRoute.color:
    dragNewConnectionVisual.default_color = activeRoute.color        
  if newRoutePoints.size() == 0:    
    newRouteConnectionContainer.show()
    newRoutePoints.append(startPoint)
    dragNewConnectionVisual.points = [startPoint]

func update_drag_new_route(currentMousePosition: Vector2) -> void:
  if is_dragging_new_connection():
    for mapNode in get_map_nodes():
      var connectionPoint = mapNode.get_connection_point()
      if connectionPoint.distance_to(currentMousePosition) < (get_viewport().size.x * .005):
        # Evaluate the existing connections with all the new drawn points
        var segmentArray = []
        for connection in activeRoute.connections:
          segmentArray.append([connection.get_start_point(), connection.get_end_point()])
        for i in newRoutePoints.size() - 1:
          segmentArray.append([newRoutePoints[i], newRoutePoints[i + 1]])
        segmentArray.append([newRoutePoints[newRoutePoints.size() - 1], connectionPoint])
        if activeRoute.is_segment_list_valid_as_route(segmentArray):
          newRoutePoints.append(connectionPoint)
          dragNewConnectionVisual.points = newRoutePoints
          mapNode.on_connect()
    # Update the last point of the new route visuals, which should follow the cursor position
    if dragNewConnectionVisual.points.size() == newRoutePoints.size():
      dragNewConnectionVisual.add_point(currentMousePosition)
    dragNewConnectionVisual.points[dragNewConnectionVisual.points.size() - 1] = currentMousePosition

func hide_drag_new_connection() -> void:
  dragNewConnectionVisual.clear_points()
  newRouteConnectionContainer.hide()
  newRoutePoints.clear()

func is_dragging_new_connection() -> bool:
  return newRoutePoints.size() > 0

func blur_all_connections(except: Connection = null) -> void:
  for route in routes:
    for connection in route.connections:
      if connection != except:
        connection.blur()
