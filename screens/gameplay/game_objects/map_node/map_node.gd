extends Area2D
class_name MapNode

var connectRouteSFX: AudioStreamPlayer2D

func _ready():
  setup_sfx()

func setup_sfx() -> void:
  # Resources
  var connectSFXResource = load("res://sfx/pop.wav")
  # Players
  connectRouteSFX = AudioStreamPlayer2D.new()
  add_child(connectRouteSFX)
  connectRouteSFX.stream = connectSFXResource
  

func get_connection_point() -> Vector2:
  return Vector2(position.x, position.y)

func on_connect() -> void:
  connectRouteSFX.play()
