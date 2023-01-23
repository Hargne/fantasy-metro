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