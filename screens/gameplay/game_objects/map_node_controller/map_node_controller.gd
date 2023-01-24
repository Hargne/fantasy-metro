extends Node2D
class_name MapNodeController

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")
var Route = load("res://screens/gameplay/game_objects/route/route.class.gd")
# Connections / Routes
var routes = []

var connectionContainer: Node2D
var connectionPrefab = preload("res://screens/gameplay/game_objects/route/connection.tscn")
var dragNewConnectionVisual: Line2D

# SFX
onready var placeRouteSFX = $PlaceRouteSFX
onready var placeBuildingSFX = $PlaceBuildingSFX
onready var demolishSFX = $DemolishSFX
onready var gameplay = get_parent()

signal on_increase_stock(item, amount)
signal on_decrease_stock(item, amount)

func _ready():
  # Create a container for routes
  connectionContainer = Node2D.new()
  add_child(connectionContainer)
  move_child(connectionContainer, 0)

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
  blur_all_connections()

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
  route.color = gameplay.routeColors[route.routeIndex]
  routes.append(route)  
  return route

func get_connection_by_map_nodes(node1: MapNode, node2: MapNode, route: Route = null) -> Dictionary:
  for rte in routes:
    if route == null || rte == route:
      for connection in rte.connections:
        if connection.mapNodes.has(node1) && connection.mapNodes.has(node2):
          return connection
  return {}

func are_nodes_connected(node1: MapNode, node2: MapNode, route: Route) -> bool:
  return !get_connection_by_map_nodes(node1, node2, route).empty()

func connect_map_nodes(from: MapNode, to: MapNode, route: Route) -> void:
  if from == to || route == null:
    return
  if are_nodes_connected(from, to, route):
    printerr("Nodes are already connected")
    return

  var connection = spawn_connection(from, to, route)
  route.connections.append(connection)

  placeRouteSFX.play()

func spawn_connection(from: MapNode, to: MapNode, route: Route) -> Connection:
  var connection = connectionPrefab.instance()
  connection.route = route
  connection.mapNodes = [from, to]
  connection.segments = [from.get_connection_point(), to.get_connection_point()]
  connection.width = 2
  connection.lineColor = gameplay.routeColors[route.routeIndex]
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

func update_drag_new_connection_points(from: Vector2, to: Vector2) -> void:
  # Spawn a Line2D if non-existant
  if !dragNewConnectionVisual:
    dragNewConnectionVisual = Line2D.new()
    dragNewConnectionVisual.points = [from, to]
    dragNewConnectionVisual.width = 3
    dragNewConnectionVisual.default_color = gameplay.activeRoute.color
    dragNewConnectionVisual.antialiased = true
    dragNewConnectionVisual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    dragNewConnectionVisual.end_cap_mode = Line2D.LINE_CAP_ROUND 
    connectionContainer.add_child(dragNewConnectionVisual)
  # Update line points
  dragNewConnectionVisual.points[0] = from
  dragNewConnectionVisual.points[1] = to

func hide_drag_new_connection() -> void:
  update_drag_new_connection_points(Vector2.ZERO, Vector2.ZERO)

func is_dragging_new_connection() -> bool:
  return dragNewConnectionVisual && dragNewConnectionVisual.points.size() > 1 && dragNewConnectionVisual.points[0] != Vector2.ZERO && dragNewConnectionVisual.points[1] != Vector2.ZERO

func blur_all_connections(except: Connection = null) -> void:
  for route in routes:
    for connection in route.connections:
      if connection != except:
        connection.blur()
