extends Node2D
class_name CartController

var carts = []

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var cartPrefab = preload("res://screens/gameplay/game_objects/map_node/cart/cart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.CART:
      var cart = cartPrefab.instance()
      add_child(cart)
      objectBeingPlaced = cart	
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object(routeData) -> int:
  if canPlaceObject:
    if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
      objectBeingPlaced.place_on_route(routeData)
      carts.append(objectBeingPlaced)
  else:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
  return canPlaceObject

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null
