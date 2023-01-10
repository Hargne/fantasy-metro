extends MapNode
class_name ResourceNode
func get_class(): return "ResourceNode"

enum ResourceType { WATER, WOOD, STONE }
export(ResourceType) var resourceType = ResourceType.WATER
onready var sprite = $Sprite
onready var collision = $CollisionShape2D

func _ready():
  setup()

func setup() -> void:
  connectionPoint = Vector2(position.x, position.y + collision.shape.extents.y)
  match resourceType:
    ResourceType.WATER:
      sprite.region_rect.position = Vector2(16 * 1, 0)
    ResourceType.WOOD:
      sprite.region_rect.position = Vector2(16 * 2, 0)
    ResourceType.STONE:
      sprite.region_rect.position = Vector2(16 * 3, 0)
