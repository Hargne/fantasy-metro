extends Node2D
class_name MapNodeController

var connectionContainer: Node2D
var dragConnectionLine: Line2D
var currentlyDraggingConnectionFrom: MapNode
var connections = []
var isMovingNode = false
var currentlyMovingNode: Node
onready var actionPanel: ActionPanel = $ActionPanel
var activeBuildOption = GameplayEnums.BuildOption.ROUTE
var buildStock = {
  GameplayEnums.BuildOption.WAREHOUSE: 1,
  GameplayEnums.BuildOption.ROUTE: 2,
  GameplayEnums.BuildOption.CART: 1,
}
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")

func _ready():
  # Connect map node callbacks
  for child in get_children():
    if child is MapNode:
      setup_map_node(child)
  # Create a container for connection lines 
  connectionContainer = Node2D.new()
  add_child(connectionContainer)
  move_child(connectionContainer, 0)
  # Connect Action Panel
  Utils.connect_signal(actionPanel, "started_dragging_object", self, "on_initiated_placing_object")
  # Allow for nodes to get initialized
  yield(get_tree().create_timer(0.1), "timeout")
  actionPanel.update_stock(buildStock)

func _process(_delta):
  if isMovingNode && currentlyMovingNode:
    currentlyMovingNode.position = get_global_mouse_position()

func _input(event):
  if isMovingNode:
    if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.pressed:
      isMovingNode = false
      if currentlyMovingNode:
        setup_map_node(currentlyMovingNode)
        currentlyMovingNode = null

  if currentlyDraggingConnectionFrom:
    # Update dragging line position
    if event is InputEventMouseMotion:
      set_drag_connection_line_points(currentlyDraggingConnectionFrom.get_connection_point(), get_global_mouse_position())
    # Upon releasing drag
    if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
      if !event.pressed:
        yield(get_tree().create_timer(0.1), "timeout")
        hide_drag_connection_line()

func setup_map_node(mapNode: MapNode) -> void:
  Utils.connect_signal(mapNode, "on_click", self, "on_mapnode_click")
  Utils.connect_signal(mapNode, "on_click_released", self, "on_mapnode_click_release")

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

func spawn_connection_line2D(from: Vector2, to: Vector2) -> Line2D:
  var connectionLine = Line2D.new()
  connectionContainer.add_child(connectionLine)
  connectionLine.points = [from, to]
  connectionLine.width = 3
  connectionLine.default_color = Color("#cccccc")
  connectionLine.antialiased = true
  connectionLine.begin_cap_mode = Line2D.LINE_CAP_ROUND
  connectionLine.end_cap_mode = Line2D.LINE_CAP_ROUND
  return connectionLine

func set_drag_connection_line_points(from: Vector2, to: Vector2) -> void:
  # Spawn a Line2D if non-existant
  if !dragConnectionLine:
    dragConnectionLine = spawn_connection_line2D(from, to)
  # Update line points
  dragConnectionLine.points[0] = from
  dragConnectionLine.points[1] = to

func hide_drag_connection_line() -> void:
  currentlyDraggingConnectionFrom = null
  set_drag_connection_line_points(Vector2.ZERO, Vector2.ZERO)

func get_node_connections(mapNode: MapNode) -> Array:
  var relatedConnections = []
  for connectionData in connections:
    if "mapNodes" in connectionData && connectionData.mapNodes.has(mapNode):
      relatedConnections.append(connectionData)
  return relatedConnections

func are_nodes_connected(node1: MapNode, node2: MapNode) -> bool:
  for connectionData in connections:
    if "mapNodes" in connectionData && connectionData.mapNodes.has(node1) && connectionData.mapNodes.has(node2):
      return true
  return false

func create_connection_between_nodes(from: MapNode, to: MapNode) -> void:
  if are_nodes_connected(from, to):
    printerr("Nodes are already connected")
    return
  connections.append({
    "mapNodes": [from, to],
    "connection": spawn_connection_line2D(from.get_connection_point(), to.get_connection_point())
  })

func get_connection_between_nodes(node1: MapNode, node2: MapNode) -> Line2D:
  for connectionData in connections:
    if "mapNodes" in connectionData && connectionData.mapNodes.has(node1) && connectionData.mapNodes.has(node2):
      if "connection" in connectionData && is_instance_valid(connectionData.connection): 
        return connectionData.connection
  return null

func on_mapnode_click(mapNode: MapNode) -> void:
  if activeBuildOption == GameplayEnums.BuildOption.ROUTE && buildStock[GameplayEnums.BuildOption.ROUTE] > 0:
    currentlyDraggingConnectionFrom = mapNode
    set_drag_connection_line_points(mapNode.position, mapNode.position)

func on_mapnode_click_release(mapNode: MapNode) -> void:
  if activeBuildOption == GameplayEnums.BuildOption.ROUTE && buildStock[GameplayEnums.BuildOption.ROUTE] > 0:
    if currentlyDraggingConnectionFrom && currentlyDraggingConnectionFrom != mapNode && !are_nodes_connected(currentlyDraggingConnectionFrom, mapNode):
      create_connection_between_nodes(currentlyDraggingConnectionFrom, mapNode)
      buildStock[GameplayEnums.BuildOption.ROUTE] -= 1
      actionPanel.set_build_option_amount(GameplayEnums.BuildOption.ROUTE, buildStock[GameplayEnums.BuildOption.ROUTE])

func on_initiated_placing_object(objectToBePlaced) -> void:
  match objectToBePlaced:
    GameplayEnums.BuildOption.WAREHOUSE:
      var warehouse = warehouseNodePrefab.instance()
      add_child(warehouse)
      currentlyMovingNode = warehouse
  isMovingNode = true
  buildStock[objectToBePlaced] -= 1
  actionPanel.set_build_option_amount(objectToBePlaced, buildStock[objectToBePlaced])
