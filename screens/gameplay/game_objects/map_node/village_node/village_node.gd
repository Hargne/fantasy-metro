extends MapNode
class_name VillageNode
func get_class(): return "VillageNode"

onready var demandedResources = $ResourceList
export var maxResourceDemands = 6
# Flags
onready var flagLeft = $FlagL
onready var flagRight = $FlagR
var color = Color("#639bff")

func _ready():
  set_color(color)

func can_add_resource_demand() -> bool:
  return demandedResources.resources.size() < maxResourceDemands

func add_resource_demand(resourceType) -> void:
  if can_add_resource_demand():
    demandedResources.add_resource(resourceType)
    
func remove_demand(resourceType) -> void:
  if demandedResources.resources.size() > 0:
    demandedResources.remove_resource(resourceType)

func set_color(inputColor: Color) -> void:
  flagLeft.modulate = inputColor
  flagRight.modulate = inputColor
