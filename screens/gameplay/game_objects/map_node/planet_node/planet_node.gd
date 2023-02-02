extends MapNode
class_name PlanetNode
func get_class(): return "PlanetNode"

onready var travellers = $TravellerList
export var maxTravellers = 6
export var planetType = GameplayEnums.PlanetType.WATER

func get_texture_for_planet_type() -> String:
  match planetType:
    GameplayEnums.PlanetType.WATER:
      return 'blueplanet.png'
    GameplayEnums.PlanetType.JUNGLE:
      return 'greenplanet.png'
    GameplayEnums.PlanetType.LAVA:
      return 'redplanet.png'
    GameplayEnums.PlanetType.ACID:
      return 'purpleplanet.png' 

  return 'blueplanet.png'                 

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
