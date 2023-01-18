extends Node2D
class_name MapNodeController

var routeContainer: Node2D
var dragNewRouteVisual: Line2D
var routes = []
var carts = []
var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var warehouseNodePrefab = preload("res://screens/gameplay/game_objects/map_node/warehouse_node/warehouse_node.tscn")
var cartPrefab = preload("res://screens/gameplay/game_objects/map_node/cart/cart.tscn")

var normalRouteColor = "#cccccc"
var availableRouteColor = "#ffffff"
var highlightedRouteColor = "#0000ff"

var roadWidth = 3.0

var route_id: int = 100

func _ready():
	# Create a container for routes
	routeContainer = Node2D.new()
	add_child(routeContainer)
	move_child(routeContainer, 0)

func _process(_delta):
	if objectBeingPlaced:
		if canPlaceObject && objectBeingPlaced.modulate.a == 0.5:
			objectBeingPlaced.modulate.a = 1
		elif !canPlaceObject && objectBeingPlaced.modulate.a == 1:
			objectBeingPlaced.modulate.a = 0.5

func get_village_nodes() -> Array:
	var nodes = []
	for child in get_children():
		if child is VillageNode:
			nodes.append(child)
	return nodes

func get_resource_nodes() -> Array:
	var nodes = []
	for child in get_children():
		if child is ResourceNode:
			nodes.append(child)
	return nodes

func spawn_route(from: Vector2, to: Vector2) -> Line2D:
	var route = Line2D.new()
	routeContainer.add_child(route)
	route.points = [from, to]
	route.width = roadWidth
	route.default_color = Color(normalRouteColor)
	route.antialiased = true
	route.begin_cap_mode = Line2D.LINE_CAP_ROUND
	route.end_cap_mode = Line2D.LINE_CAP_ROUND  
	return route

func update_drag_new_route_points(from: Vector2, to: Vector2) -> void:
	# Spawn a Line2D if non-existant
	if !dragNewRouteVisual:
		dragNewRouteVisual = spawn_route(from, to)
	# Update line points
	dragNewRouteVisual.points[0] = from
	dragNewRouteVisual.points[1] = to

func hide_drag_new_route() -> void:
	update_drag_new_route_points(Vector2.ZERO, Vector2.ZERO)

func is_dragging_new_route() -> bool:
	return dragNewRouteVisual && dragNewRouteVisual.points.size() > 1 && dragNewRouteVisual.points[0] != Vector2.ZERO && dragNewRouteVisual.points[1] != Vector2.ZERO

func get_node_routes(mapNode: MapNode) -> Array:
	var relatedRoutes = []
	for routeData in routes:
		if "mapNodes" in routeData && routeData.mapNodes.has(mapNode):
			relatedRoutes.append(routeData)
	return relatedRoutes

func are_nodes_connected(node1: MapNode, node2: MapNode) -> bool:
	for routeData in routes:
		if "mapNodes" in routeData && routeData.mapNodes.has(node1) && routeData.mapNodes.has(node2):
			return true
	return false

func create_route_between_nodes(from: MapNode, to: MapNode) -> void:
	if from == to:
		return
	if are_nodes_connected(from, to):
		printerr("Nodes are already connected")
		return

	var fromPt = from.get_connection_point()
	var toPt = to.get_connection_point()

	var routeData = {
		"routeID": route_id,
		"mapNodes": [from, to],
		"fromNode": from, 
		"toNode": to,
		"fromPt": fromPt,
		"toPt": toPt,
		"route": spawn_route(fromPt, toPt),
		"radians" : fromPt.angle_to_point(toPt),
		"degrees" : fromPt.angle_to_point(toPt) * (180 / PI),
		"rect": Rect2(Vector2(fromPt.x if fromPt.x < toPt.x else toPt.x, fromPt.y if fromPt.y < toPt.y else toPt.y), Vector2(abs(fromPt.x - toPt.x), abs(fromPt.y - toPt.y))),
		"poly": Utils.get_rectangle_polygon_from_two_points_and_width(from.get_connection_point(), to.get_connection_point(), roadWidth * 4),
	}

	route_id += 1

	routes.append(routeData)

func get_route_between_nodes(node1: MapNode, node2: MapNode) -> Line2D:
	for routeData in routes:
		if "mapNodes" in routeData && routeData.mapNodes.has(node1) && routeData.mapNodes.has(node2):
			if "route" in routeData && is_instance_valid(routeData.route): 
				return routeData.route
	return null

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
	typeOfObjectBeingPlaced = objectTypeToBePlaced
	match objectTypeToBePlaced:
		GameplayEnums.BuildOption.WAREHOUSE:
			var warehouse = warehouseNodePrefab.instance()
			add_child(warehouse)
			objectBeingPlaced = warehouse
		GameplayEnums.BuildOption.CART:
			var cart = cartPrefab.instance()
			add_child(cart)
			objectBeingPlaced = cart	
	if objectBeingPlaced:
		objectBeingPlaced.position = startPosition

func end_place_new_object() -> int:
	if canPlaceObject:
		if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
			var routeData = get_route_data_from_point(objectBeingPlaced.position)		

			objectBeingPlaced.place_on_route(routeData)
			carts.append(objectBeingPlaced)
	else:
		# Cancel placement by removing the new object
		if objectBeingPlaced:
			objectBeingPlaced.queue_free()
	return canPlaceObject

func stop_placing_object() -> void:
	objectBeingPlaced = null
	typeOfObjectBeingPlaced = null
	unhighlight_available_routes()

func is_placing_new_object() -> bool:
	return objectBeingPlaced != null && is_instance_valid(objectBeingPlaced)

func does_point_intersect_any_routes(point) -> bool:
	for routeData in routes: 
		var poly = routeData.poly
		if Geometry.is_point_in_polygon(point, poly.polygon):
			return true    
	return false

func get_route_data_from_point(point, strict = false) -> Dictionary:
	for routeData in routes: 
		if strict:
			var poly = routeData.poly
			if Geometry.is_point_in_polygon(point, poly.polygon):
				return routeData
		else:
			var rect = routeData.rect
			if rect.has_point(point):
				return routeData
	return {}

func get_route_by_id(id) -> Dictionary:
	for routeData in routes: 
		if (routeData.routeID == id):
			return routeData
	return {}
		

func highlight_available_route(routeData) -> void:	
	routeData.route.default_color = Color(highlightedRouteColor)

func unhighlight_available_routes() -> void:
	for routeData in routes:
		routeData.route.default_color = Color(normalRouteColor)
