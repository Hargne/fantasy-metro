extends Node2D
class_name MapNodeController

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")
var Route = load("res://screens/gameplay/game_objects/route/route.class.gd")
# Connections / Routes
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
onready var placeRouteSFX = $PlaceRouteSFX
onready var placeBuildingSFX = $PlaceBuildingSFX
onready var demolishSFX = $DemolishSFX

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
# BUILDINGS/RESOURCES
#################################################################      

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
    if child is WarehouseNode || child is VillageNode || child is ResourceNode:
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

  placeRouteSFX.play()

  newRoutePoints.clear()
  newRouteConnectionContainer.hide()

func spawn_connection(from: MapNode, to: MapNode, route: Route) -> Connection:
  var connection = connectionPrefab.instance()
  connection.route = route
  connection.mapNodes = [from, to]
  connection.segments = [from.get_connection_point(), to.get_connection_point()]
  connection.width = 2
  connection.lineColor = routeColors[route.routeIndex]
  connectionContainer.add_child(connection)
  Utils.connect_signal(connection, "on_demolish", self, "demolish_connection")
  return connection  

func demolish_connection(connection: Connection) -> void:
  delete_connection(connection)  
  demolishSFX.play()

func delete_connection(connection: Connection) -> void:
  if is_instance_valid(connection):
    connection.queue_free()
    for route in routes:
      route.connections.erase(connection)

func get_connection_from_point(point: Vector2) -> Connection:
  var matchedConnections = []
  for route in routes:
    for connection in route.connections:
      var startPoint = connection.get_start_point()
      var endPoint = connection.get_end_point()

      var rect = Rect2(
        Vector2(
          startPoint.x if startPoint.x < endPoint.x else endPoint.x,
          startPoint.y if startPoint.y < endPoint.y else endPoint.y
        ),
        Vector2(
          abs(startPoint.x - endPoint.x),
          abs(startPoint.y - endPoint.y)
        )
      )

      if rect.has_point(point):
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

func draw_new_route_nodes(startPt, currentMousePosition) -> void:
  if newRoutePoints.size() == 0:    
    newRouteConnectionContainer.show()
    newRoutePoints.append(startPt)
  else:
    for nd in get_map_nodes():      
      var cpt = nd.get_connection_point()
      if !newRoutePoints.has(cpt) && cpt.distance_to(currentMousePosition) < (get_viewport().size.x * .005):
        newRoutePoints.append(cpt)

    # check to see if we added a new node to our collection

  for n in newRouteConnectionContainer.get_children():
    newRouteConnectionContainer.remove_child(n)
    n.queue_free()  

  for i in newRoutePoints.size():
    var pt1 = newRoutePoints[i]
    var pt2 = newRoutePoints[i + 1] if i < newRoutePoints.size() - 1 else currentMousePosition

    dragNewConnectionVisual = Line2D.new()
    dragNewConnectionVisual.points = [pt1, pt2]
    dragNewConnectionVisual.width = 1.5
    dragNewConnectionVisual.default_color = activeRoute.color
    dragNewConnectionVisual.antialiased = true
    dragNewConnectionVisual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    dragNewConnectionVisual.end_cap_mode = Line2D.LINE_CAP_ROUND 
    if dragNewConnectionVisual.default_color != activeRoute.color:
      dragNewConnectionVisual.default_color = activeRoute.color    
    newRouteConnectionContainer.add_child(dragNewConnectionVisual)    

func hide_drag_new_connection() -> void:
  for n in newRouteConnectionContainer.get_children():
    newRouteConnectionContainer.remove_child(n)
    n.queue_free()  
  newRouteConnectionContainer.hide()
  newRoutePoints.clear()

func is_dragging_new_connection() -> bool:
  return newRoutePoints.size() > 0

func blur_all_connections(except: Connection = null) -> void:
  for route in routes:
    for connection in route.connections:
      if connection != except:
        connection.blur()
