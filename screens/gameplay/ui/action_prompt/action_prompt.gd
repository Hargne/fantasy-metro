extends PanelContainer

onready var deleteBtn = $CenterContainer/GridContainer/Delete
onready var moveBtn = $CenterContainer/GridContainer/Move
onready var upgradeBtn = $CenterContainer/GridContainer/Upgrade

var isVisible = false
var transitionSpeed = 10

func _ready():
  modulate.a = 0

func _process(delta):
  if isVisible:
    modulate.a = lerp(modulate.a, 1, transitionSpeed * delta)
  elif modulate.a > 0:
    modulate.a = lerp(modulate.a, 0, transitionSpeed * delta)
