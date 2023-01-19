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
      var warehouse = warehouseNodePrefab.instance()
      add_child(warehouse)
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object() -> void:
  if canPlaceObject:
    emit_signal("on_decrease_stock", typeOfObjectBeingPlaced)
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
    if "mapNodes" in connection && connection.mapNodes.has(node1) && connection.mapNodes.has(node2):
      return connection
  return {}

func get_connection_by_route(route: Route) -> Dictionary:
  for connection in nodeConnections:
    if "route" in connection && connection.route == route:
      return connection
  return {}

func are_nodes_connected(node1: MapNode, node2: MapNode) -> bool:
  return !get_connection_by_map_nodes(node1, node2).empty()

func spawn_route(from: Vector2, to: Vector2, width = 3) -> Route:
  var route = routePrefab.instance()
  route.segments = [from, to]
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
  nodeConnections.append({
    "mapNodes": [from, to],
    "route": spawn_route(from.get_connection_point(), to.get_connection_point())
  })
  emit_signal("on_decrease_stock", GameplayEnums.BuildOption.ROUTE)

func demolish_route(route: Route) -> void:
  var relatedConnection = get_connection_by_route(route)
  if relatedConnection:
    delete_connection(relatedConnection)
    emit_signal("on_increase_stock", GameplayEnums.BuildOption.ROUTE)

func delete_connection(connection: Dictionary) -> void:
  if "route" in connection && is_instance_valid(connection.route):
    connection.route.queue_free()
    nodeConnections.erase(connection)

func does_point_intersect_any_routes(point: Vector2) -> bool:
  for connection in nodeConnections: 
    if Geometry.is_point_in_polygon(point, connection.route.get_intersecting_rectangle().polygon):
      return true    
  return false

func get_route_from_point(point: Vector2, strict = false) -> Route:
  for connection in nodeConnections: 
    if strict && does_point_intersect_any_routes(point):
      return connection.route
    else:
      var startPoint = connection.route.get_start_point()
      var endPoint = connection.route.get_end_point()
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
        return connection.route
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
    if "route" in connection && is_instance_valid(connection.route) && connection.route != except:
      connection.route.blur()
