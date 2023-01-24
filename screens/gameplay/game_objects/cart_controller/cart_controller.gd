extends Node2D
class_name CartController

var carts = []

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var cartPrefab = preload("res://screens/gameplay/game_objects/cart_controller/cart.tscn")

onready var placeCartSFX = $PlaceCartSFX

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.CART:
      var cart = cartPrefab.instance()
      add_child(cart)
      objectBeingPlaced = cart	
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object(connection: Connection) -> int:
  if connection:
    if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
      objectBeingPlaced.place_on_connection(connection)
      carts.append(objectBeingPlaced)
      placeCartSFX.play()
    stop_placing_object()      
  else:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
    stop_placing_object()      
  return canPlaceObject

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null
