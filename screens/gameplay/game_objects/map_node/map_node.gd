extends Area2D
class_name MapNode

signal on_click(mapNode)
signal on_click_released(mapNode)

func _input_event(_viewport, event, _shape_idx):
  if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
    if event.pressed:
      emit_signal("on_click", self)
    else:
      emit_signal("on_click_released", self)

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y + 6)
