extends Node

func connect_signal(
  signalNode: Node,
  signalMethod: String,
  receivingNode: Node,
  callbackMethod: String,
  params: Array = []
) -> void:
  if signalNode.connect(signalMethod, receivingNode, callbackMethod, params) != OK:
    printerr("Could not connect " + signalNode.name + " -> " + signalMethod + " to " + receivingNode.name + " -> " + callbackMethod)

func get_rectangle_polygon_from_two_points_and_width(p1 : Vector2, p2 : Vector2, w : float) -> Rect2:  
  var v = Vector2(p2.x - p1.x, p2.y - p1.y) # line vector
  var p = Vector2(v.y, -v.x) # perpendicular vector
  var length = sqrt(p.x * p.x + p.y * p.y) # lentgh of perp
  var n = Vector2(p.x / length, p.y / length) # normalized perp vector

  var wh = w / 2 # half width
  
  var poly = Polygon2D.new()
  poly.set_polygon(PoolVector2Array([Vector2(p1.x + n.x * wh, p1.y + n.y * wh),
                                  Vector2(p1.x - n.x * wh, p1.y - n.y * wh),
                                  Vector2(p2.x + n.x * wh, p2.y + n.y * wh),
                                  Vector2(p2.x - n.x * wh, p2.y - n.y * wh)
                                ]))
  
  return poly

func get_line_segments(p1 : Vector2, p2 : Vector2, segments: int) -> Array:
  var dx = (p2.x - p1.x) / segments 
  var dy = (p2.y - p1.y) / segments

  var pts = [];

  pts.append(p1)

  for i in range(1,1 + segments):
    pts.append(Vector2(p1.x + (i*dx), p1.y + (i*dy)))

    pts.append(p2)

  return pts
