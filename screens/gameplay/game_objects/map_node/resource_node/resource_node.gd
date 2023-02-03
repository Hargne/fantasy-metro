extends MapNode
class_name ResourceNode
func get_class(): return "ResourceNode"

onready var resourceTypeVisualsContainer = $Types
export(GameplayEnums.TravellerType) var resourceType = GameplayEnums.TravellerType.BLUE_TRAVELLER

func _ready():
  setup_visuals()

func setup_visuals() -> void:
  # Display the correct resource visuals based on name
  for c in resourceTypeVisualsContainer.get_children():
    if c.name.to_upper() == GameplayEnums.TravellerType.keys()[resourceType]:
      c.visible = true
    else:
      c.visible = false
