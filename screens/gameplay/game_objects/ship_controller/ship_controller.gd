extends Node2D
class_name ShipController

var ships = []

signal on_increase_stock(item, amount)
signal on_decrease_stock(item, amount)

var objectBeingPlaced: Node
var canPlaceObject = false
var typeOfObjectBeingPlaced
var shipPrefab = preload("res://screens/gameplay/game_objects/ship_controller/ship.tscn")

onready var placeShipSFX = $PlaceShipSFX
onready var demolishSFX = $DemolishSFX

func initiate_place_new_object(objectTypeToBePlaced, startPosition: Vector2) -> void:
  typeOfObjectBeingPlaced = objectTypeToBePlaced
  match objectTypeToBePlaced:
    GameplayEnums.BuildOption.SHIP:
      var ship = shipPrefab.instance()
      add_child(ship)
      objectBeingPlaced = ship	
  if objectBeingPlaced:
    objectBeingPlaced.position = startPosition

func end_place_new_object(connection: Connection) -> void:
  if connection:
    if typeOfObjectBeingPlaced == GameplayEnums.BuildOption.SHIP:
      objectBeingPlaced.place_on_connection(connection)
      ships.append(objectBeingPlaced)
      Utils.connect_signal(objectBeingPlaced, "on_demolish", self, "demolish_ship")
      placeShipSFX.play()
    stop_placing_object()
  else:
    # Cancel placement by removing the new object
    if objectBeingPlaced:
      objectBeingPlaced.queue_free()
    stop_placing_object()

func stop_placing_object() -> void:
  objectBeingPlaced = null
  typeOfObjectBeingPlaced = null

func blur_all_ships(except: Ship = null) -> void:
  for ship in ships:
    if (ship == null || ship != except):
      ship.blur()

func demolish_ship(ship) -> void:
  if is_instance_valid(ship):
    emit_signal("on_increase_stock", GameplayEnums.BuildOption.SHIP)
    ship.queue_free()
    ships.erase(ship)
  demolishSFX.play()
