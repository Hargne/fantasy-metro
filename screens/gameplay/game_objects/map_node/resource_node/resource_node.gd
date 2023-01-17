extends MapNode
class_name ResourceNode
func get_class(): return "ResourceNode"

onready var visualsContainer = $Visuals
export(GameplayEnums.Resource) var resourceType = GameplayEnums.Resource.WATER

func _ready():
  setup_visuals()

func setup_visuals() -> void:
  # Display the correct resource visuals based on name
  for c in visualsContainer.get_children():
    if c.name.to_upper() == GameplayEnums.Resource.keys()[resourceType]:
      c.visible = true
    else:
      c.visible = false
