extends MapNode
class_name WarehouseNode
func get_class(): return "WarehouseNode"

onready var storedResources = $ResourceList

export var capacity = 6

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y + 6)

func has_capacity() -> bool:
  return storedResources.resources.size() < capacity

func add_resource(resourceType) -> void:
  if has_capacity():
    storedResources.add_resource(resourceType)

func remove_resource(resourceType) -> void:
  if storedResources.resources.size() > 0:
    storedResources.remove_resource(resourceType)
