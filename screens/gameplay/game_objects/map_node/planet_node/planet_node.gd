extends MapNode
class_name PlanetNode
func get_class(): return "PlanetNode"

onready var travellerList = $TravellerList
export var maxTravellers = 6
export var planetType = GameplayEnums.PlanetType.BLUE

func get_texture_for_planet_type() -> String:
  match planetType:
    GameplayEnums.PlanetType.BLUE:
      return 'blueplanet.png'
    GameplayEnums.PlanetType.GREEN:
      return 'greenplanet.png'
    GameplayEnums.PlanetType.RED:
      return 'redplanet.png'
    GameplayEnums.PlanetType.PURPLE:
      return 'purpleplanet.png' 

  return 'blueplanet.png'                 

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y)

func can_add_traveller() -> bool:
  return travellerList.travellers.size() < maxTravellers

func add_traveller(travellerType) -> void:
  if can_add_traveller():
    travellerList.add_traveller(travellerType)
    
func remove_traveller(travellerType) -> void:
  if travellerList.travellers.size() > 0:
    travellerList.remove_traveller(travellerType)

func demands_traveller_pickup(travellerType) -> bool:
  return travellerList.contains_traveller(travellerType)

func has_travellers() -> bool:
  return travellerList.travellers.size() > 0
