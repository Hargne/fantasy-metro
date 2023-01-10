extends VBoxContainer

export var maxResources = 99
export var columns = 6
var resources = []
onready var centerContainer = $CenterContainer
onready var gridContainer = $CenterContainer/GridContainer
var textureBasePath = "res://screens/gameplay/game_objects/resource_list/assets"
var iconSize = 16

func _ready():
  var size = columns * (iconSize + 10)
  gridContainer.columns = columns
  rect_min_size.x = size
  rect_position.x = size / -4
  centerContainer.rect_min_size.x = size

func add_resource(resourceType) -> void:
  if resources.size() >= maxResources - 1:
    printerr("Max resource amount reached")
    return
  var icon = TextureRect.new()
  gridContainer.add_child(icon)
  icon.rect_size = Vector2(iconSize, iconSize)
  # Grab texture
  var textureFile
  match resourceType:
    ResourceNode.ResourceType.STONE:
      textureFile = "stone_icon.tres"
    ResourceNode.ResourceType.WATER:
      textureFile = "water_icon.tres"
    ResourceNode.ResourceType.WOOD:
      textureFile = "wood_icon.tres"
  # Make sure that the file exist
  if !textureFile:
    printerr("Invalid resource type: " + resourceType)
    return
  icon.texture = load(textureBasePath + "/" + textureFile)
  resources.append({ "node": icon, "resourceType": resourceType })

func remove_resource(resourceType) -> void:
  for resource in resources:
    if "resourceType" in resource && resource.resourceType == resourceType:
      # Remove the icon node
      if "node" in resource && is_instance_valid(resource.node):
        resource.node.queue_free()
      resources.erase(resourceType)
      
func clear() -> void:
  resources.clear()
  for c in gridContainer.get_children():
    gridContainer.remove_child(c)
    c.queue_free()
