extends Node2D
class_name Map

onready var activeTilemap = $TileMap
var buildableTileName = "ground"
  
func get_tile_position_in_world(position: Vector2) -> Vector2:
  return activeTilemap.map_to_world(activeTilemap.world_to_map(position)) + activeTilemap.cell_size / 2

func is_tile_buildable(position: Vector2) -> bool:
  var tileIndex = activeTilemap.get_cellv(activeTilemap.world_to_map(position))
  if tileIndex > 0:
    return activeTilemap.tile_set.tile_get_name(tileIndex) == buildableTileName
  return false
