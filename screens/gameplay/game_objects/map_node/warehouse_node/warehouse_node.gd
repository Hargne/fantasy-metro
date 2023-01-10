extends MapNode
class_name WarehouseNode
func get_class(): return "WarehouseNode"

onready var collision = $CollisionShape2D
onready var resourceList = $ResourceList

export var capacity = 6

func _ready():
  connectionPoint = Vector2(position.x, position.y + collision.shape.extents.y)

func has_capacity() -> bool:
  return resourceList.resources.size() < capacity

func add_resource(resourceType) -> void:
  if has_capacity():
    resourceList.add_resource(resourceType)

func remove_resource(resourceType) -> void:
  if resourceList.resources.size() > 0:
    resourceList.remove_resource(resourceType)
