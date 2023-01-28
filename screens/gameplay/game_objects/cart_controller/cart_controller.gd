extends Node2D
class_name CartController

var carts = []

signal on_increase_stock(item, amount)
signal on_decrease_stock(item, amount)

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var cartPrefab = preload("res://screens/gameplay/game_objects/cart_controller/cart.tscn")

onready var placeCartSFX = $PlaceCartSFX
onready var demolishSFX = $DemolishSFX

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.CART:
      var cart = cartPrefab.instance()
      add_child(cart)
      objectBeingPlaced = cart	
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object(connection: Connection) -> void:
  if connection:
    if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.CART:
      objectBeingPlaced.place_on_connection(connection)
      carts.append(objectBeingPlaced)
      Utils.connect_signal(objectBeingPlaced, "on_demolish", self, "demolish_cart")
      placeCartSFX.play()
    stop_placing_object()
  else:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
    stop_placing_object()

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null

func blur_all_carts(except: Cart = null) -> void:
  for cart in carts:
    if (cart == null || cart != except):
      cart.blur()

func demolish_cart(cart) -> void:
  if is_instance_valid(cart):
    emit_signal("on_increase_stock", GameplayEnums.BuildOption.CART)
    cart.queue_free()
    carts.erase(cart)
  demolishSFX.play()
