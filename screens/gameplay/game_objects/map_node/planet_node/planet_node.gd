extends MapNode
class_name PlanetNode
func get_class(): return "PlanetNode"

onready var travellers = $TravellerList
export var maxTravellers = 6

func _draw():
  draw_circle(position, 16, Color("#0000ff"))

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y)

func can_add_traveller() -> bool:
  return travellers.resources.size() < maxTravellers

func add_traveller(travellerType) -> void:
  if can_add_traveller():
    travellers.add_resource(travellerType)
    
func remove_traveller(travellerType) -> void:
  if travellers.resources.size() > 0:
    travellers.remove_resource(travellerType)

func demands_traveller_pickup(travellerType) -> bool:
  return travellers.contains_resource(travellerType)

func has_travellers() -> bool:
  return travellers.resources.size() > 0
