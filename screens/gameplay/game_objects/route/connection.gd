extends Node2D
class_name Connection

signal on_demolish(connection)

var connectionID = 0
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
  Utils.connect_signal(actionPrompt, "on_button_clicked", self, "action_prompt_button_pressed")

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
  _targetHighlightAmount = 1
  if showPrompt:
    actionPrompt.display(get_center_point(), [ActionPrompt.ButtonType.DELETE])
    if !can_be_deleted():
      actionPrompt.disable_button(ActionPrompt.ButtonType.DELETE)

func is_highlighted() -> bool:
  return _targetHighlightAmount == 1

func blur() -> void:
  _targetHighlightAmount = 0
  yield(get_tree().create_timer(0.1), "timeout")
  actionPrompt.hide()

func can_be_deleted() -> bool:
  if route.connections.size() < 3:
    return true

  var proposedConnectionSegments = []

  for conn in route.connections:
    if conn == self:
      continue
    proposedConnectionSegments.append([conn.segments[0], conn.segments[1]])
  return route.is_segment_list_valid_as_route(proposedConnectionSegments) 

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

func demolish() -> void:
  emit_signal("on_demolish", self)

func change_color(newColor: Color) -> void:
  self.lineColor = newColor
  line.default_color = newColor
  
func action_prompt_button_pressed(buttonType) -> void:
  if buttonType == ActionPrompt.ButtonType.DELETE:
    emit_signal("on_demolish", self)

