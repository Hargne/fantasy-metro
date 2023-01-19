extends Area2D
class_name Cart

onready var storedResources = $ResourceList

var defaultCartSpeed = 1.0

export var capacity = 1
export var destinationPt = Vector2(0,0)
export var cartSpeed = 1
export var startPt = Vector2(0,0)
var currentRoute: Route

func has_capacity() -> bool:
  return storedResources.resources.size() < capacity

func add_resource(resourceType) -> void:
  if has_capacity():
    storedResources.add_resource(resourceType)

func remove_resource(resourceType) -> void:
  if storedResources.resources.size() > 0:
    storedResources.remove_resource(resourceType)

func place_on_route(route: Route) -> void:
  # first, normalize the placement so it is on the line
  var pt1 = route.get_start_point() 
  var pt2 = route.get_end_point()
  currentRoute = route

  var pts = Utils.get_line_segments(pt1, pt2, 4)
  var closestDist = 99999999
  var closestPt = Vector2(0, 0)

  # we place the cart in one of 5 junction points, depending on which it is closest to, facing the direction of the map node it's closest to
  for pt in pts:
    var d = pt.distance_to(position)
    if d < closestDist:
      closestPt = pt
      closestDist = d		

  position = closestPt	

  startPt = pt2 if closestPt.distance_to(pt1) < closestPt.distance_to(pt2) else pt1
  destinationPt = pt1 if closestPt.distance_to(pt1) < closestPt.distance_to(pt2) else pt2
  cartSpeed = defaultCartSpeed

  look_at(destinationPt)
  
