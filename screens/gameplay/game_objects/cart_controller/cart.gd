extends Area2D
class_name Cart

onready var storedResources = $ResourceList

var defaultCartSpeed = .1

export var capacity = 1
export var startPt = Vector2(0,0)
export var destinationPt = Vector2(0,0)
export var cartSpeed = .1
var currentRoute: Route
var currentStatus = RouteStatus.IN_PROGRESS

var arrivalTime = 0
var arrivalDelay = 500 # we use a .5 second delay for actions to take place

enum RouteStatus {
  IN_PROGRESS,
  JUST_ARRIVED,
  LOADING,
  UNLOADING,
  WAITING,
  EXITING
}

func _process(_delta):
  if currentStatus != RouteStatus.IN_PROGRESS || position.distance_to(destinationPt) < .05: # this is a magic number for now - probably will need to be based on map size or screen size or something
    do_destination_handling()
  else:
    move_cart_to_destination()    

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

func move_cart_to_destination() -> void:
  position = position.move_toward(destinationPt, cartSpeed)

func do_destination_handling() -> void:  
  if currentStatus == RouteStatus.IN_PROGRESS:
    currentStatus = RouteStatus.JUST_ARRIVED
    arrivalTime = Time.get_ticks_msec()
  elif currentStatus == RouteStatus.JUST_ARRIVED:
    var t = Time.get_ticks_msec()

    if (t - arrivalTime) > arrivalDelay:      
      begin_destination_action()

# in progress......
func begin_destination_action() -> void:
  if !storedResources.resources.empty():
    true # unload

  var destinationNode = currentRoute.get_map_node_from_point(destinationPt)

  


  
