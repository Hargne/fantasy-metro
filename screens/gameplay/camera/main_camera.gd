extends Camera2D


# Declare member variables here. Examples:
var pan_speed = 100

var _previousPosition: Vector2 = Vector2(0, 0);
var _moveCamera: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var x_delta = 0
	var y_delta = 0

	if Input.is_action_pressed("pan_map_right"):
		x_delta += pan_speed * delta

	if Input.is_action_pressed("pan_map_left"):
		x_delta -= pan_speed * delta

	if Input.is_action_pressed("pan_map_down"):
		y_delta += pan_speed * delta

	if Input.is_action_pressed("pan_map_up"):
		y_delta -= pan_speed * delta 

	position.x += x_delta 
	position.y += y_delta
		
func _input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT:
		if event.is_pressed():
			_previousPosition = event.position;
			_moveCamera = true;
		else:
			_moveCamera = false;
	elif event is InputEventMouseMotion && _moveCamera:
		position += (_previousPosition - event.position);
		_previousPosition = event.position;




