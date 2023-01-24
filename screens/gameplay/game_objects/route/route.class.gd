class_name Route
var routeIndex: int = -1
var connections: Array = []
var color: Color = Color.black

func get_all_connections_for_map_node(mapNode) -> Array:
  var matchingConnections = []

  for connection in connections:
    if connection.mapNodes.has(mapNode):
      matchingConnections.append(connection)

  return matchingConnections

# gets demands for cart as if cart just pulled into the starting destination point and will continue forward from there
func get_demands_along_route(startConnection, startDestinationPt) -> Array:
  var demands = []

  if connections.size() == 0:
    return demands  

  # look forwards from destination pt
  var orderedMapNodes = get_ordered_map_nodes(startConnection, startDestinationPt)
  
  for mapNode in orderedMapNodes:
    if mapNode is VillageNode:
      for demandedResource in mapNode.demandedResources.resources:
        demands.append(demandedResource.resourceType)

  # look backwards from destination pt (we do this second so upcoming demands have higher priority
  # note: if we have a circular loop, we will repeat demands in opposite order going backwards
  orderedMapNodes = get_ordered_map_nodes(startConnection, startConnection.get_other_point(startDestinationPt), true)

  for mapNode in orderedMapNodes:
    if mapNode is VillageNode:
      for demandedResource in mapNode.demandedResources.resources:
        demands.append(demandedResource.resourceType)

  return demands

func get_ordered_map_nodes(startConnection, startPt, includeStartNodeInList: bool = false) -> Array:
  var orderedMapNodes = []

  if includeStartNodeInList:
    orderedMapNodes.append(startConnection.get_map_node_from_point(startPt))

  var connectionsSeen = []
  connectionsSeen.append(startConnection)

  var foundNewConnection = true

  while foundNewConnection:
    foundNewConnection = false

    for connection in connections:
      if connection.has_point(startPt) && !connectionsSeen.has(connection):
        foundNewConnection = true
        connectionsSeen.append(connection)

        var mapNode = connection.get_map_node_from_point(startPt)

        if !orderedMapNodes.has(mapNode):
          orderedMapNodes.append(mapNode)

        startPt = connection.get_other_point(startPt)
        mapNode = connection.get_map_node_from_point(startPt)

        if !orderedMapNodes.has(mapNode):
          orderedMapNodes.append(mapNode) 

    if connectionsSeen.size() == connections.size():
      break         

  return orderedMapNodes  

func get_ordered_connections(startConnection, startPt, includeStartConnectionInList: bool = false) -> Array:
  var orderedConnections = []

  if includeStartConnectionInList:
    orderedConnections.append(startConnection)

  var connectionsSeen = []
  connectionsSeen.append(startConnection)

  var foundNewConnection = true

  while foundNewConnection:
    foundNewConnection = false

    for connection in connections:
      if connection.has_point(startPt) && !connectionsSeen.has(connection):
        foundNewConnection = true
        connectionsSeen.append(connection)
        orderedConnections.append(connection)
        startPt = connection.get_other_point(startPt)

    if connectionsSeen.size() == connections.size():
      break

  return orderedConnections

  