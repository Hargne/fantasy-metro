extends VBoxContainer
class_name PopupList

var animationPlayer: AnimationPlayer
var transition_init = preload("res://screens/gameplay/ui/popup_list/panel_transition_init.tres")
var transition_out = preload("res://screens/gameplay/ui/popup_list/panel_transition_out.tres")
var transition_in = preload("res://screens/gameplay/ui/popup_list/panel_transition_in.tres")
export var displayOnStartup = false

func _ready():
  animationPlayer = AnimationPlayer.new()
  add_child(animationPlayer)
  if animationPlayer.add_animation("transition_init", transition_init) != OK:
    printerr("could not add animation 'transition_init'")
  if animationPlayer.add_animation("transition_out", transition_out) != OK:
    printerr("could not add animation 'transition_out'")
  if animationPlayer.add_animation("transition_in", transition_in) != OK:
    printerr("could not add animation 'transition_in'")
  Utils.connect_signal(animationPlayer, "animation_finished", self, "on_animation_finish")
  if !displayOnStartup:
    hide(true)

func _input(event):
  if visible:
    # Check whether the user clicks outside this component
    if (event is InputEventMouseButton) and event.pressed:
      if !Rect2(Vector2(0,0),rect_size).has_point(make_input_local(event).position):
        hide()

func display() -> void:
  visible = true
  animationPlayer.play("transition_in")

func hide(instant = false) -> void:
  if instant:
    animationPlayer.play("transition_init")
    visible = false
  else:
    animationPlayer.play("transition_out")

func on_animation_finish(animationName: String) -> void:
  if animationName == "transition_out":
    visible = false
