extends Node2D
class_name Connection

signal on_demolish(connection)

var width: float
var route = null
var mapNodes = []
var segments: PoolVector2Array
var lineColor = Color("#3f1605")
var _currentHighlightAmount = 0
var _targetHighlightAmount = 0

# Refs
onready var line = $Line2D
onready var actionPrompt = $ActionPrompt

func _ready():
  setup_visuals()
  Utils.connect_signal(actionPrompt, "action_prompt_button_pressed", self, "action_prompt_button_pressed")

func _process(delta):
  if _currentHighlightAmount != _targetHighlightAmount:
    _currentHighlightAmount = lerp(_currentHighlightAmount, _targetHighlightAmount, 10 * delta)
    line.default_color = lineColor.lightened(_currentHighlightAmount)

func setup_visuals() -> void:
  line.points = segments
  line.width = width
  line.default_color = lineColor
  line.antialiased = true
  line.begin_cap_mode = Line2D.LINE_CAP_ROUND
  line.end_cap_mode = Line2D.LINE_CAP_ROUND 

func highlight(showPrompt = false) -> void:  
  if can_be_deleted():
    _targetHighlightAmount = 1
    if showPrompt:
      actionPrompt.display(get_center_point(), [ActionPrompt.ButtonType.DELETE])

func can_be_deleted() -> bool:
  if route.connections.size() < 3:
    return true

  var connectedConnections = 0

  for conn in route.connections:
    if conn == self:
      continue

    var nd1 = conn.get_start_node()
    var nd2 = conn.get_end_node()

    var conn1 = route.get_all_connections_for_map_node(nd1)
    conn1.erase(conn)
    conn1.erase(self)
    var conn2 = route.get_all_connections_for_map_node(nd2)
    conn2.erase(conn)
    conn2.erase(self)

    if conn1.size() > 0 || conn2.size() > 0:
      connectedConnections = connectedConnections + 1

  return connectedConnections >= (route.connections.size() - 1)

func blur() -> void:
  _targetHighlightAmount = 0
  actionPrompt.hide()

func get_start_node() -> MapNode:
  return mapNodes[0]

func get_end_node() -> MapNode:
  return mapNodes[mapNodes.size() - 1]


func get_start_point() -> Vector2:
  return segments[0]

func get_end_point() -> Vector2:
  return segments[segments.size() - 1]

func get_map_node_from_point(point) -> MapNode:
  return mapNodes[0] if segments[0] == point else mapNodes[1]

func get_point_from_map_node(mapNode) -> Vector2:
  return segments[0] if mapNodes[0] == mapNode else segments[1]

func contains_point(point) -> bool:
  return segments.has(point)

func contains_node(mapNode) -> bool:
  return mapNodes.has(mapNode)

func get_other_point(point) -> Vector2:
  return segments[0] if segments[1] == point else segments[1]

func get_other_node(mapNode) -> MapNode:
  return mapNodes[0] if mapNodes[1] == mapNode else mapNodes[1]

func get_intersecting_rectangle() -> Rect2:
  return Utils.get_rectangle_polygon_from_two_points_and_width(
    get_start_point(),
    get_end_point(),
    width * 4
  )

func get_center_point() -> Vector2:
  return 0.5 * (get_start_point() + get_end_point())

func action_prompt_button_pressed(buttonName) -> void:
  if (buttonName.to_upper() == 'DELETE'):
    emit_signal("on_demolish", self)