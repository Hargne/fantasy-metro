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

# gets planet types on route as if ship just pulled into the starting destination point and will continue forward from there
func get_planet_types_along_route(startConnection, startDestinationPt, includeStartDestination: bool = true, lookBothDirections: bool = false) -> Array:
  var planetTypes = []

  if connections.size() == 0:
    return planetTypes  

  # look forwards from destination pt
  var orderedMapNodes = get_ordered_map_nodes(startConnection, startDestinationPt)
  if orderedMapNodes.size() == 0: # this means we are at the end, so we will be turning around
    lookBothDirections = true
  
  for mapNode in orderedMapNodes:
    if mapNode is PlanetNode:
      if !includeStartDestination && mapNode.get_connection_point() == startDestinationPt:
        continue
      planetTypes.append(mapNode.planetType)        

  if lookBothDirections:
    # look backwards from destination pt (we do this second so upcoming demands have higher priority
    # note: if we have a circular loop, we will repeat demands in opposite order going backwards
    orderedMapNodes = get_ordered_map_nodes(startConnection, startConnection.get_other_point(startDestinationPt), true)

    for mapNode in orderedMapNodes:
      if mapNode is PlanetNode:
        if !includeStartDestination && mapNode.get_connection_point() == startDestinationPt:
          continue
        planetTypes.append(mapNode.planetType)        

  return planetTypes

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
      if connection.contains_point(startPt) && !connectionsSeen.has(connection):
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

func get_number_of_open_nodes() -> int:
  if connections.size() == 0:
    return 0

  if connections.size() == 1:
    return 2

  var openEndedSegments = 0

  for conn in connections:
    var pt1 = conn.get_start_point()
    var segmentsWithPtCount = 0
    for connInner in connections:    
      if connInner.contains_point(pt1):
        segmentsWithPtCount += 1

    if segmentsWithPtCount == 1:
      openEndedSegments += 1   

    var pt2 = conn.get_end_point()
    segmentsWithPtCount = 0
    for connInner in connections:    
      if connInner.contains_point(pt2):
        segmentsWithPtCount += 1

    if segmentsWithPtCount == 1:
      openEndedSegments += 1         

  return openEndedSegments

func is_segment_list_valid_as_route(segmentList) -> bool:
  if segmentList.size() == 0:
    return false

  if segmentList.size() == 1:
    return true
  
  var openEndedSegments = 0

  for segmentArray in segmentList:
    var pt1 = segmentArray[0]
    var segmentsWithPtCount = 0
    for segmentArrayInner in segmentList:    
      if segmentArrayInner[0] == pt1 || segmentArrayInner[1] == pt1:
        segmentsWithPtCount += 1

    if segmentsWithPtCount == 1:
      openEndedSegments += 1
    elif segmentsWithPtCount > 2:
      return false

    var pt2 = segmentArray[1]
    segmentsWithPtCount = 0
    for segmentArrayInner in segmentList:    
      if segmentArrayInner[0] == pt2 || segmentArrayInner[1] == pt2:
        segmentsWithPtCount += 1

    if segmentsWithPtCount == 1:
      openEndedSegments += 1
    elif segmentsWithPtCount > 2:
      return false

  return openEndedSegments == 0 || openEndedSegments == 2

  