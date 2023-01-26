extends Area2D
class_name Cart

onready var storedResources = $ResourceList
onready var actionPrompt = $ActionPrompt

signal on_demolish(cart)

var defaultCartSpeed = .1 if ApplicationManager.debugMode else .1

export var capacity = 1
export var startPt = Vector2(0,0)
export var destinationPt = Vector2(0,0)
export var cartSpeed = .1
var currentConnection: Connection
var currentStatus = CartStatus.EN_ROUTE

var stepTimeStamp = 0
var stepDelay = 500 # we use a .5 second delay for actions to take place

enum CartStatus {
  EN_ROUTE,
  JUST_ARRIVED,  
  UNLOADING,
  LOADING,
  EXITING,
  WAITING
}

func _ready():
  Utils.connect_signal(actionPrompt, "action_prompt_button_pressed", self, "action_prompt_button_pressed")

func _process(_delta):
  if currentStatus != CartStatus.EN_ROUTE || position.distance_to(destinationPt) < .05: # this is a magic number for now - probably will need to be based on map size or screen size or something
    cart_is_at_destination()
  else:
    if currentConnection:
      move_cart_to_destination()      

func has_capacity() -> bool:
  return storedResources.resources.size() < capacity

func add_resource(resourceType) -> void:
  if has_capacity():
    storedResources.add_resource(resourceType)

func remove_resource(resourceType) -> void:
  if storedResources.resources.size() > 0:
    storedResources.remove_resource(resourceType)

func place_on_connection(connection: Connection) -> void:
  # first, normalize the placement so it is on the line
  var pt1 = connection.get_start_point() 
  var pt2 = connection.get_end_point()
  currentConnection = connection

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
  currentStatus = CartStatus.EN_ROUTE

  look_at(destinationPt)

func move_cart_to_destination() -> void:
  position = position.move_toward(destinationPt, cartSpeed)

func cart_is_at_destination() -> void:  
  if currentStatus == CartStatus.EN_ROUTE:
    currentStatus = CartStatus.JUST_ARRIVED
    position = destinationPt # make sure it is set to exact spot since the destination is triggered at .05 pixels
    stepTimeStamp = Time.get_ticks_msec()
  else:
    var t = Time.get_ticks_msec()

    if (t - stepTimeStamp) > stepDelay:      
      do_destination_action()

# in progress......
func do_destination_action() -> void:
  var destinationNode = currentConnection.get_map_node_from_point(destinationPt)

  if currentStatus == CartStatus.JUST_ARRIVED:
    do_just_arrived_action(destinationNode)    
  elif currentStatus == CartStatus.UNLOADING:
    do_unloading_action(destinationNode)
  elif currentStatus == CartStatus.LOADING:
    do_loading_action(destinationNode)
  elif currentStatus == CartStatus.EXITING:
    do_exiting_action(destinationNode)

func do_just_arrived_action(destinationNode) -> void:
  # show arrival graphics, smoke from cart stopping, etc... or just slow cart down  
  # the if statements below allow us to skip uneeded steps right away
  if destinationNode is VillageNode:
    if storedResources.resources.size() > 0 && destinationNode.has_demands():
      currentStatus = CartStatus.UNLOADING
    else: 
      currentStatus = CartStatus.EXITING
  elif destinationNode is ResourceNode:
    if has_capacity():      
      currentStatus = CartStatus.LOADING
    else:
      currentStatus = CartStatus.EXITING
  elif destinationNode is WarehouseNode:
    if storedResources.resources.size() > 0 && destinationNode.has_capacity():
      currentStatus = CartStatus.UNLOADING
    elif destinationNode.has_stock() && has_capacity():    
      currentStatus = CartStatus.LOADING    
    else:
      currentStatus = CartStatus.EXITING

func do_unloading_action(destinationNode) -> void:  
  var unloadedResourceType

  if destinationNode is VillageNode:
    for resource in storedResources.resources:
      if "resourceType" in resource && destinationNode.demands_resource(resource.resourceType):
        unloadedResourceType = resource.resourceType          
        storedResources.remove_resource(unloadedResourceType, false)        
        destinationNode.demandedResources.remove_resource(unloadedResourceType, false)
        # show little icon moving from cart to village      
        break  
  elif destinationNode is WarehouseNode:
    # the warehouse node takes ANYTHING up to capacity;
    # however, don't drop anything that we still need further on the route

    var demandedResourcesOnRoute = currentConnection.route.get_demands_along_route(currentConnection, currentConnection.get_point_from_map_node(destinationNode))

    if destinationNode.has_capacity():
      for resource in storedResources.resources:
        if "resourceType" in resource:
          if demandedResourcesOnRoute.has(resource.resourceType):
            continue # don't drop this resource

          unloadedResourceType = resource.resourceType  
          storedResources.remove_resource(unloadedResourceType, false) 

          # show little icon moving from cart to warehouse

          # NOTE: some resource types get upgraded at this stage, and the resource type that was unloaded is NOT the same
          # as the resource that the warehouse will hold (like mana ore -> mana crystals)
          destinationNode.add_resource(unloadedResourceType)

          break        

  if !unloadedResourceType:
    currentStatus = CartStatus.LOADING

  stepTimeStamp = Time.get_ticks_msec()

func do_loading_action(destinationNode) -> void:  
  var loadedResourceType  

  if has_capacity():
    if destinationNode is ResourceNode:
      loadedResourceType = destinationNode.resourceType

      # show little icon moving from resource to cart
      storedResources.add_resource(loadedResourceType)
    elif destinationNode is WarehouseNode:
      var demandedResourcesOnRoute = currentConnection.route.get_demands_along_route(currentConnection, currentConnection.get_point_from_map_node(destinationNode))

      if demandedResourcesOnRoute.size() > 0:
        # remove all the resources we already have, so we don't add them again
        # note: we have to do this because we add 1 resource per loading action cycle (500 ms)
        for storedResource in storedResources.resources:
          var demandedRscIdx = demandedResourcesOnRoute.find(storedResource.resourceType)
          demandedResourcesOnRoute.remove(demandedRscIdx)

        for demandedResource in demandedResourcesOnRoute:
          for resource in destinationNode.storedResources.resources:
            if "resourceType" in resource && resource.resourceType == demandedResource:
              # show little icon moving from warehouse to cart
              loadedResourceType = resource.resourceType
              destinationNode.storedResources.remove_resource(loadedResourceType)
              storedResources.add_resource(loadedResourceType)
              break

          if loadedResourceType:
            break
      else:
        for resource in destinationNode.storedResources.resources:
          if "resourceType" in resource:
            # show little icon moving from warehouse to cart
            loadedResourceType = resource.resourceType
            destinationNode.storedResources.remove_resource(loadedResourceType)
            storedResources.add_resource(loadedResourceType)
            break

  if !loadedResourceType:
    currentStatus = CartStatus.EXITING

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

  currentStatus = CartStatus.EN_ROUTE

func cart_clicked() -> void:     
  # TODO: DISPLAY THE PROMPT ROTATED PROPERLY FOR THE CART
  actionPrompt.display(Vector2(0, 0), [ActionPrompt.ButtonType.DELETE])

func blur() -> void:
  actionPrompt.hide()
      

func action_prompt_button_pressed(buttonName) -> void:
  if (buttonName.to_upper() == 'DELETE'):
    emit_signal('on_demolish', self)
  
