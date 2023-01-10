extends MapNode
class_name VillageNode
func get_class(): return "VillageNode"

onready var sprite = $Sprite
onready var collision = $CollisionShape2D
onready var resourceList = $ResourceList

export var maxResourceDemands = 6

func _ready():
  connectionPoint = Vector2(position.x, position.y + collision.shape.extents.y)

func add_resource_demand(resourceType) -> void:
  if can_add_resource_demand():
    resourceList.add_resource(resourceType)

func can_add_resource_demand() -> bool:
  return resourceList.resources.size() < maxResourceDemands
