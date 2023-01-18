extends MapNode
class_name CartNode
func get_class(): return "CartNode"

onready var storedResources = $ResourceList

export var capacity = 1

func has_capacity() -> bool:
  return storedResources.resources.size() < capacity

func add_resource(resourceType) -> void:
  if has_capacity():
    storedResources.add_resource(resourceType)

func remove_resource(resourceType) -> void:
  if storedResources.resources.size() > 0:
    storedResources.remove_resource(resourceType)
