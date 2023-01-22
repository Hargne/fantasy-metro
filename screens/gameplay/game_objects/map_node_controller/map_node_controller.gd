extends Node2D
class_name MapNodeController

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")
# Connections / Routes
var nodeConnections = []
var routeContainer: Node2D
var routePrefab = preload("res://screens/gameplay/game_objects/route/route.tscn")
var dragNewRouteVisual: Line2D
# SFX
onready var placeRouteSFX = $PlaceRouteSFX
onready var placeBuildingSFX = $PlaceBuildingSFX
onready var demolishSFX = $DemolishSFX

signal on_increase_stock(item, amount)
signal on_decrease_stock(item, amount)

func _ready():
  # Create a container for routes
  routeContainer = Node2D.new()
  add_child(routeContainer)
  move_child(routeContainer, 0)

func _process(_delta):
  if objectBeingPlaced:
    if canPlaceObject && objectBeingPlaced.modulate.a == 0.5:
      objectBeingPlaced.modulate.a = 1
    elif !canPlaceObject && objectBeingPlaced.modulate.a == 1:
      objectBeingPlaced.modulate.a = 0.5

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
  blur_all_routes()

func is_placing_new_object() -> bool:
  return objectBeingPlaced != null && is_instance_valid(objectBeingPlaced)

#
# Connections / Routes
#

func get_connection_by_map_nodes(node1: MapNode, node2: MapNode) -> Dictionary:
  for connection in nodeConnections:
    if connection.mapNodes.has(node1) && connection.mapNodes.has(node2):
      return connection
  return {}

func are_nodes_connected(node1: MapNode, node2: MapNode) -> bool:
  return !get_connection_by_map_nodes(node1, node2).empty()

func spawn_route(from: MapNode, to: MapNode, width = 3) -> Route:
  var route = routePrefab.instance()
  route.mapNodes = [from, to]
  route.segments = [from.get_connection_point(), to.get_connection_point()]
  route.width = width
  routeContainer.add_child(route)
  Utils.connect_signal(route, "on_demolish", self, "demolish_route")
  return route

func connect_map_nodes(from: MapNode, to: MapNode) -> void:
  if from == to:
    return
  if are_nodes_connected(from, to):
    printerr("Nodes are already connected")
    return

  nodeConnections.append(spawn_route(from, to))
  
  emit_signal("on_decrease_stock", GameplayEnums.BuildOption.ROUTE)
  placeRouteSFX.play()

func demolish_route(route: Route) -> void:
  delete_connection(route)
  emit_signal("on_increase_stock", GameplayEnums.BuildOption.ROUTE)
  demolishSFX.play()

func delete_connection(route: Route) -> void:
  if is_instance_valid(route):
    route.queue_free()
    nodeConnections.erase(route)

func does_point_intersect_any_routes(point: Vector2) -> bool:
  for connection in nodeConnections: 
    if Geometry.is_point_in_polygon(point, connection.get_intersecting_rectangle().polygon):
      return true    
  return false

func get_route_from_point(point: Vector2) -> Route:
  var matchedConnections = []
  for connection in nodeConnections: 
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

func update_drag_new_route_points(from: Vector2, to: Vector2) -> void:
  # Spawn a Line2D if non-existant
  if !dragNewRouteVisual:
    dragNewRouteVisual = Line2D.new()
    dragNewRouteVisual.points = [from, to]
    dragNewRouteVisual.width = 3
    dragNewRouteVisual.default_color = Color("#96ffffff")
    dragNewRouteVisual.antialiased = true
    dragNewRouteVisual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    dragNewRouteVisual.end_cap_mode = Line2D.LINE_CAP_ROUND 
    routeContainer.add_child(dragNewRouteVisual)
  # Update line points
  dragNewRouteVisual.points[0] = from
  dragNewRouteVisual.points[1] = to

func hide_drag_new_route() -> void:
  update_drag_new_route_points(Vector2.ZERO, Vector2.ZERO)

func is_dragging_new_route() -> bool:
  return dragNewRouteVisual && dragNewRouteVisual.points.size() > 1 && dragNewRouteVisual.points[0] != Vector2.ZERO && dragNewRouteVisual.points[1] != Vector2.ZERO

func blur_all_routes(except: Route = null) -> void:
  for connection in nodeConnections:
    if connection != except:
      connection.blur()
