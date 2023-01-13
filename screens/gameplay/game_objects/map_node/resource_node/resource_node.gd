extends MapNode
class_name ResourceNode
func get_class(): return "ResourceNode"

export(GameplayEnums.Resource) var resourceType = GameplayEnums.Resource.WATER
onready var sprite = $Sprite
onready var collision = $CollisionShape2D

func _ready():
  setup()

func setup() -> void:
  match resourceType:
    GameplayEnums.Resource.WATER:
      sprite.region_rect.position = Vector2(16 * 1, 0)
    GameplayEnums.Resource.WOOD:
      sprite.region_rect.position = Vector2(16 * 2, 0)
    GameplayEnums.Resource.STONE:
      sprite.region_rect.position = Vector2(16 * 3, 0)
