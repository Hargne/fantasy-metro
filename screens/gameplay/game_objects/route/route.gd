extends Node2D
class_name Route

signal on_demolish(route)

var width: float
var segments: PoolVector2Array
var lineColor = Color("#aaaaaa")
var _currentHighlightAmount = 0
var _targetHighlightAmount = 0

# Refs
onready var line = $Line2D
onready var actionPrompt = $ActionPrompt

func _ready():
  setup_visuals()
  Utils.connect_signal(actionPrompt.deleteButton, "pressed", self, "demolish")

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

func highlight() -> void:
  _targetHighlightAmount = 1
  actionPrompt.display(get_center_point(), [ActionPrompt.ButtonType.DELETE])

func blur() -> void:
  _targetHighlightAmount = 0
  actionPrompt.hide()

func get_start_point() -> Vector2:
  return segments[0]

func get_end_point() -> Vector2:
  return segments[segments.size() - 1]

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
