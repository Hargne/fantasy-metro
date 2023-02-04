extends Area2D
class_name Ship

onready var travellerList = $TravellerList
onready var actionPrompt = $ActionPrompt
onready var routeLine = $RouteLine

signal on_demolish(ship)

var defaultShipSpeed = .33 if ApplicationManager.debugMode else .1

export var capacity = 2
export var startPt = Vector2(0,0)
export var destinationPt = Vector2(0,0)
export var shipSpeed = .1
var currentConnection: Connection
var currentStatus = ShipStatus.EN_ROUTE

var stepTimeStamp = 0
var stepDelay = 200 if ApplicationManager.debugMode else 500

enum ShipStatus {
  EN_ROUTE,
  JUST_ARRIVED,  
  UNLOADING,
  LOADING,
  EXITING,
  WAITING
}

func _ready():
  Utils.connect_signal(actionPrompt, "on_button_clicked", self, "action_prompt_button_pressed")

func _process(_delta):
  if currentStatus != ShipStatus.EN_ROUTE || position.distance_to(destinationPt) < .05: # this is a magic number for now - probably will need to be based on map size or screen size or something
    ship_is_at_destination()
  else:
    if currentConnection:
      move_ship_to_destination()      

func has_capacity() -> bool:
  return travellerList.travellers.size() < capacity

func add_traveller(travellerType) -> void:
  if has_capacity():
    travellerList.add_traveller(travellerType)

func remove_traveller(travellerType) -> void:
  if travellerList.travellers.size() > 0:
    travellerList.remove_traveller(travellerType)

func place_on_connection(connection: Connection) -> void:
  # first, normalize the placement so it is on the line
  var pt1 = connection.get_start_point() 
  var pt2 = connection.get_end_point()
  currentConnection = connection

  var pts = Utils.get_line_segments(pt1, pt2, 4)
  var closestDist = 99999999
  var closestPt = Vector2(0, 0)

  # we place the ship in one of 5 junction points, depending on which it is closest to, facing the direction of the map node it's closest to
  for pt in pts:
    var d = pt.distance_to(position)
    if d < closestDist:
      closestPt = pt
      closestDist = d		

  position = closestPt	

  startPt = pt2 if closestPt.distance_to(pt1) < closestPt.distance_to(pt2) else pt1
  destinationPt = pt1 if closestPt.distance_to(pt1) < closestPt.distance_to(pt2) else pt2
  shipSpeed = defaultShipSpeed
  currentStatus = ShipStatus.EN_ROUTE

  routeLine.default_color = connection.route.color

  look_at(destinationPt)

func move_ship_to_destination() -> void:
  position = position.move_toward(destinationPt, shipSpeed)

func ship_is_at_destination() -> void:  
  if currentStatus == ShipStatus.EN_ROUTE:
    currentStatus = ShipStatus.JUST_ARRIVED
    position = destinationPt # make sure it is set to exact spot since the destination is triggered at <= .05 pixels
    stepTimeStamp = Time.get_ticks_msec()
  else:
    var t = Time.get_ticks_msec()

    if (t - stepTimeStamp) > stepDelay:      
      do_destination_action()

# in progress......
func do_destination_action() -> void:
  var destinationNode = currentConnection.get_map_node_from_point(destinationPt)

  if currentStatus == ShipStatus.JUST_ARRIVED:
    do_just_arrived_action(destinationNode)    
  elif currentStatus == ShipStatus.UNLOADING:
    do_unloading_action(destinationNode)
  elif currentStatus == ShipStatus.LOADING:
    do_loading_action(destinationNode)
  elif currentStatus == ShipStatus.EXITING:
    do_exiting_action(destinationNode)

func do_just_arrived_action(destinationNode) -> void:
  # show arrival graphics, smoke from ship stopping, etc... or just slow ship down  
  # the if statements below allow us to skip uneeded steps right away
  if destinationNode is PlanetNode:
    if travellerList.travellers.size() > 0 && travellerList.contains_traveller(destinationNode.planetType):
      currentStatus = ShipStatus.UNLOADING
    elif destinationNode.travellerList.travellers.size() > 0:
      currentStatus = ShipStatus.LOADING # TODO: ONLY PICK UP PASSENGERS ON OUR ROUTE
    else:
      currentStatus = ShipStatus.EXITING 

func do_unloading_action(destinationNode) -> void:  
  var unloadedTravellerType = false

  if destinationNode is PlanetNode:
    for traveller in travellerList.travellers:
      if destinationNode.planetType == traveller.travellerType:
        unloadedTravellerType = traveller.travellerType          
        travellerList.remove_traveller(unloadedTravellerType, false)        
        destinationNode.travellerList.remove_traveller(unloadedTravellerType, false)
        destinationNode.happiness += 5.0
        destinationNode.update_happiness_factors()
        # show little icon moving from ship to planet
        break       

  if !unloadedTravellerType:
    currentStatus = ShipStatus.LOADING

  stepTimeStamp = Time.get_ticks_msec()

func do_loading_action(destinationNode) -> void:  
  var loadedTravellerType  

  if has_capacity():
    var planetTypesOnRoute = currentConnection.route.get_planet_types_along_route(currentConnection, currentConnection.get_point_from_map_node(destinationNode), false, false)

    if destinationNode is PlanetNode:
      if planetTypesOnRoute.size() > 0:        
        # remove all the planet types we already are carrying, so we don't add them again
        # note: we have to do this because we add 1 passenger per loading action cycle (500 ms)
        for traveller in travellerList.travellers:
          var existingDemandIdx = planetTypesOnRoute.find(traveller.travellerType) # even though the array has planet types; the traveller type matches (for now)
          planetTypesOnRoute.remove(existingDemandIdx)

        for planetType in planetTypesOnRoute:
          for traveller in destinationNode.travellerList.travellers:
            if "travellerType" in traveller && traveller.travellerType == planetType:
              # show little icon moving from planet to ship
              loadedTravellerType = traveller.travellerType
              destinationNode.travellerList.remove_traveller(loadedTravellerType)
              travellerList.add_traveller(loadedTravellerType)
              break

          if loadedTravellerType:
            break
      else:
        for traveller in destinationNode.trvallerList.travellers:
          if "travellerType" in traveller:
            # show little icon moving from planet to ship
            loadedTravellerType = traveller.travellerType
            destinationNode.travellerList.remove_traveller(loadedTravellerType)
            travellerList.add_traveller(loadedTravellerType)
            break

  if !loadedTravellerType:
    currentStatus = ShipStatus.EXITING

  stepTimeStamp = Time.get_ticks_msec()

# this function determines where to go next
func do_exiting_action(destinationNode) -> void:
  var currentRoute = currentConnection.route

  var matchingConnections = currentRoute.get_all_connections_for_map_node(destinationNode)

  if matchingConnections.size() > 1:
    matchingConnections.erase(currentConnection)

  if matchingConnections.size() > 1:
    matchingConnections.shuffle()

  currentConnection = matchingConnections[0]
  startPt = destinationNode.get_connection_point()

  if currentConnection.mapNodes[0] == destinationNode:
    destinationPt = currentConnection.mapNodes[1].get_connection_point()
  else:
    destinationPt = currentConnection.mapNodes[0].get_connection_point()

  look_at(destinationPt)

  currentStatus = ShipStatus.EN_ROUTE

func ship_clicked() -> void:     
  # TODO: DISPLAY THE PROMPT ROTATED PROPERLY FOR THE SHIP
  actionPrompt.display(Vector2(0, 0), [ActionPrompt.ButtonType.DELETE])

func blur() -> void:
  actionPrompt.hide()
      

func action_prompt_button_pressed(buttonType) -> void:
  if buttonType == ActionPrompt.ButtonType.DELETE:
    emit_signal('on_demolish', self)
  
