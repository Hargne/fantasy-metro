extends CanvasLayer

signal on_start_game_pressed
signal on_continue_game_pressed

var gameIsPaused = false
var transitionSpeed = 10
var rotationAmount = 20
var transitionTimeout = 0.1
var screenHeight = 600
var offScreenY = screenHeight + 200

onready var animations = $AnimationPlayer

onready var blur = $Blur
onready var fade = $Fade
onready var versionNumberLabel = $VersionNumber
onready var startButton = $CenterContainer/VBoxContainer/CenterContainer/VBoxContainer/StartGame
onready var exitButton = $CenterContainer/VBoxContainer/CenterContainer/VBoxContainer/Exit

func _ready():
  versionNumberLabel.text = ApplicationManager.version
  var _screenDimensions = get_viewport().get_visible_rect().size
  screenHeight = _screenDimensions.y
  blur.rect_size = _screenDimensions
  fade.rect_size = _screenDimensions
  Utils.connect_signal(startButton, "pressed", self, "start_game")
  Utils.connect_signal(exitButton, "pressed", self, "exit_game")
  
func display(paused = false) -> void:
  visible = true
  animations.play("transition_in")
  if paused:
    gameIsPaused = true
    startButton.text = "Continue"
  else:
    gameIsPaused = false
    startButton.text = "Start"

func hide() -> void:
  animations.play("transition_out")

func start_game() -> void:
  if !gameIsPaused:
    emit_signal("on_start_game_pressed")
  else:
    emit_signal("on_continue_game_pressed")

func exit_game() -> void:
  get_tree().quit()

func on_animation_finished(anim_name):
  if anim_name == "transition_out":
    visible = false
