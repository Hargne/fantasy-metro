extends VBoxContainer

export var maxResources = 99
export var columns = 6
var resources = []
onready var centerContainer = $CenterContainer
onready var gridContainer = $CenterContainer/PanelContainer/GridContainer
var textureBasePath = "res://screens/gameplay/ui/resource_list/assets"
var iconSize = 26

var icons = []

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
  icon.expand = true
  icon.rect_min_size = Vector2(iconSize, iconSize)
  icons.append(icon)

  # Grab texture
  var textureFile
  match resourceType:
    GameplayEnums.Resource.BLUE_ALIEN:
      textureFile = "bluealien.png"
    GameplayEnums.Resource.RED_ALIEN:
      textureFile = "redalien.png"
    GameplayEnums.Resource.GREEN_ALIEN:
      textureFile = "greenalien.png"
    GameplayEnums.Resource.PURPLE_ALIEN:
      textureFile = "purplealien.png"
  # Make sure that the file exist
  if !textureFile:
    printerr("Invalid resource type: " + resourceType)
    return

  icon.texture = load(textureBasePath + "/" + textureFile)
  resources.append({ "node": icon, "resourceType": resourceType })

func remove_resource(resourceType, removeAll: bool = true) -> void:
  for resource in resources:
    if "resourceType" in resource && resource.resourceType == resourceType:
      # Remove the icon node
      if "node" in resource && is_instance_valid(resource.node):
        resource.node.queue_free()
      resources.erase(resource)
      if !removeAll:
        return
      
func clear() -> void:
  resources.clear()
  for c in gridContainer.get_children():
    gridContainer.remove_child(c)
    c.queue_free()

func contains_resource(resourceType) -> bool:
  for resource in resources:
    if "resourceType" in resource && resource.resourceType == resourceType:
      return true

  return false
