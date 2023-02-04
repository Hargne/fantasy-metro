extends MapNode
class_name PlanetNode
func get_class(): return "PlanetNode"

onready var travellerList = $TravellerList
onready var happinessContainer = $CenterContainer/HappinessContainer
export var maxTravellers = 6
export var planetType = GameplayEnums.PlanetType.BLUE
var happiness: float = 0
var planetLevel = 0
var heartSize = 26
var textureBasePath = "res://screens/gameplay/game_objects/map_node/assets"

var travellerPatience = 20 # a traveller waiting 20 seconds will cost 1 full happiness point

func _process(delta):
  var hDelta = (travellerList.travellers.size() * delta) / travellerPatience

  if hDelta != 0:
    happiness -= hDelta
    update_happiness_factors()

func update_happiness_factors() -> void:
  var newLevel = round(happiness / 5)

  if newLevel != planetLevel:
    planetLevel = newLevel
    for c in happinessContainer.get_children():
      happinessContainer.remove_child(c)
      c.queue_free()
    
    if planetLevel != 0:
      for n in range(0,planetLevel, 1 if planetLevel > 0 else -1):
        var heart = TextureRect.new()              
        heart.texture = load(textureBasePath + ('/cartoonheart.png' if planetLevel > 0 else '/redexclamationiconbutton.png'))
        heart.expand = true
        heart.rect_min_size = Vector2(heartSize, heartSize)
        happinessContainer.add_child(heart)


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
