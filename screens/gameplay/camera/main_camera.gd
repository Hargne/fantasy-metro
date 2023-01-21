extends Camera2D

var pan_speed = 60
var _previous_position: Vector2 = Vector2(0, 0);
var _moveCamera: bool = false;
var _keyboard_zoom_factor = .05

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
		
func _unhandled_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT:
		if event.is_pressed():
			_previous_position = event.position;
			_moveCamera = true;
		else:
			_moveCamera = false;
	elif event is InputEventMouseMotion && _moveCamera:
		position += (_previous_position - event.position);
		_previous_position = event.position;

func zoom():
	if Input.is_action_just_released('zoom_in'):
		set_zoom(get_zoom() - Vector2(_keyboard_zoom_factor, _keyboard_zoom_factor))
	if Input.is_action_just_released('zoom_out'): #and get_zoom() > Vector2.ONE:
		set_zoom(get_zoom() + Vector2(_keyboard_zoom_factor, _keyboard_zoom_factor))

func _physics_process(_delta):
	zoom()


