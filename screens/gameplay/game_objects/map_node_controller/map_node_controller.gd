extends Node2D
class_name MapNodeController

var routeContainer: Node2D
var dragNewRouteVisual: Line2D
var routes = []
var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")

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

func spawn_route(from: Vector2, to: Vector2) -> Line2D:
  var route = Line2D.new()
  routeContainer.add_child(route)
  route.points = [from, to]
  route.width = 3
  route.default_color = Color("#cccccc")
  route.antialiased = true
  route.begin_cap_mode = Line2D.LINE_CAP_ROUND
  route.end_cap_mode = Line2D.LINE_CAP_ROUND
  return route

func update_drag_new_route_points(from: Vector2, to: Vector2) -> void:
  # Spawn a Line2D if non-existant
  if !dragNewRouteVisual:
    dragNewRouteVisual = spawn_route(from, to)
  # Update line points
  dragNewRouteVisual.points[0] = from
  dragNewRouteVisual.points[1] = to

func hide_drag_new_route() -> void:
  update_drag_new_route_points(Vector2.ZERO, Vector2.ZERO)

func is_dragging_new_route() -> bool:
  return dragNewRouteVisual && dragNewRouteVisual.points.size() > 1 && dragNewRouteVisual.points[0] != Vector2.ZERO && dragNewRouteVisual.points[1] != Vector2.ZERO

func get_node_routes(mapNode: MapNode) -> Array:
  var relatedRoutes = []
  for routeData in routes:
    if "mapNodes" in routeData && routeData.mapNodes.has(mapNode):
      relatedRoutes.append(routeData)
  return relatedRoutes

func are_nodes_connected(node1: MapNode, node2: MapNode) -> bool:
  for routeData in routes:
    if "mapNodes" in routeData && routeData.mapNodes.has(node1) && routeData.mapNodes.has(node2):
      return true
  return false

func create_route_between_nodes(from: MapNode, to: MapNode) -> void:
  if from == to:
    return
  if are_nodes_connected(from, to):
    printerr("Nodes are already connected")
    return
  routes.append({
    "mapNodes": [from, to],
    "route": spawn_route(from.get_connection_point(), to.get_connection_point())
  })

func get_route_between_nodes(node1: MapNode, node2: MapNode) -> Line2D:
  for routeData in routes:
    if "mapNodes" in routeData && routeData.mapNodes.has(node1) && routeData.mapNodes.has(node2):
      if "route" in routeData && is_instance_valid(routeData.route): 
        return routeData.route
  return null

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.WAREHOUSE:
      var warehouse = warehouseNodePrefab.instance()
      add_child(warehouse)
      objectBeingPlaced = warehouse
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object() -> int:
  if !canPlaceObject:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
  return canPlaceObject

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null

func is_placing_new_object() -> bool:
  return objectBeingPlaced != null && is_instance_valid(objectBeingPlaced)
