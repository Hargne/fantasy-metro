extends Node2D
class_name MapNodeController

var connectionContainer: Node2D
var dragConnectionLine: Line2D
var currentlyDraggingConnectionFrom: MapNode
var connections = []

func _ready():
  # Connect map node callbacks
  for child in get_children():
    if child is MapNode:
      child.connect("on_click", self, "on_mapnode_click")
      child.connect("on_click_released", self, "on_mapnode_click_release")
  # Create a container for connection lines 
  connectionContainer = Node2D.new()
  add_child(connectionContainer)
  move_child(connectionContainer, 0)

func _input(event):
  if currentlyDraggingConnectionFrom:
    # Update dragging line position
    if event is InputEventMouseMotion:
      set_drag_connection_line_points(currentlyDraggingConnectionFrom.connectionPoint, get_global_mouse_position())
    # Upon releasing drag
    if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
      if !event.pressed:
        yield(get_tree().create_timer(0.1), "timeout")
        hide_drag_connection_line()

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
    "connection": spawn_connection_line2D(from.connectionPoint, to.connectionPoint)
  })

func get_connection_between_nodes(node1: MapNode, node2: MapNode) -> Line2D:
  for connectionData in connections:
    if "mapNodes" in connectionData && connectionData.mapNodes.has(node1) && connectionData.mapNodes.has(node2):
      if "connection" in connectionData && is_instance_valid(connectionData.connection): 
        return connectionData.connection
  return null

func on_mapnode_click(mapNode: MapNode) -> void:
  currentlyDraggingConnectionFrom = mapNode
  set_drag_connection_line_points(mapNode.position, mapNode.position)

func on_mapnode_click_release(mapNode: MapNode) -> void:
  if currentlyDraggingConnectionFrom && currentlyDraggingConnectionFrom != mapNode && !are_nodes_connected(currentlyDraggingConnectionFrom, mapNode):
    create_connection_between_nodes(currentlyDraggingConnectionFrom, mapNode)
