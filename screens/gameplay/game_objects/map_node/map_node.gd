extends Area2D
class_name MapNode

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y + 6)
