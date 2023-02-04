extends VBoxContainer

export var maxTravellers = 99
export var columns = 6
var travellers = []
onready var centerContainer = $CenterContainer
onready var gridContainer = $CenterContainer/PanelContainer/GridContainer
var textureBasePath = "res://screens/gameplay/ui/traveller_list/assets"
var iconSize = 26

var icons = []

func _ready():
  var size = columns * (iconSize + 10)
  gridContainer.columns = columns
  rect_min_size.x = size
  rect_position.x = size / -4
  centerContainer.rect_min_size.x = size

func add_traveller(travellerType) -> void:
  if travellers.size() >= maxTravellers - 1:
    printerr("Max travellers amount reached")
    return
  var icon = TextureRect.new()
  gridContainer.add_child(icon)
  icon.expand = true
  icon.rect_min_size = Vector2(iconSize, iconSize)
  icons.append(icon)

  # Grab texture
  var textureFile
  match travellerType:
    GameplayEnums.TravellerType.BLUE_TRAVELLER:
      textureFile = "bluetraveller.png"
    GameplayEnums.TravellerType.RED_TRAVELLER:
      textureFile = "redtraveller.png"
    GameplayEnums.TravellerType.GREEN_TRAVELLER:
      textureFile = "greentraveller.png"
    GameplayEnums.TravellerType.PURPLE_TRAVELLER:
      textureFile = "purpletraveller.png"
  # Make sure that the file exist
  if !textureFile:
    printerr("Invalid travellers type: " + travellerType)
    return

  icon.texture = load(textureBasePath + "/" + textureFile)
  travellers.append({ "node": icon, "travellerType": travellerType })

func remove_traveller(travellerType, removeAll: bool = true) -> void:
  for traveller in travellers:
    if "travellerType" in traveller && traveller.travellerType == travellerType:
      # Remove the icon node
      if "node" in traveller && is_instance_valid(traveller.node):
        traveller.node.queue_free()
      travellers.erase(traveller)
      if !removeAll:
        return
      
func clear() -> void:
  travellers.clear()
  for c in gridContainer.get_children():
    gridContainer.remove_child(c)
    c.queue_free()

func contains_traveller(travellerType) -> bool:
  for traveller in travellers:
    if "travellerType" in traveller && traveller.travellerType == travellerType:
      return true

  return false
