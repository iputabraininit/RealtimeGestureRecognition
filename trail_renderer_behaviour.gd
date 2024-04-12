extends Node2D
const BUFFER_SIZE = 150 # or 400, do a fast and slow version?
var point_count = 0 
# Called when the node enters the scene tree for the first time.
var previous_mouse_position:Vector2
var _gesturing:bool = false
var _buffer:Array[Vector2] = []
var _start_gesture_time

@export var _templateLibrary:TemplateLibraryBehaviour

@onready var _trail_line: Line2D = $Line2D
@onready var _template_line: Line2D = $TemplateLine

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if event is InputEventMouseButton && MOUSE_BUTTON_LEFT:
		_gesturing = event.is_pressed()
	
		if !_gesturing:
			_trail_line.clear_points()
			print("Stopped gesturing, recognising ", _buffer.size())
			
			var result = _templateLibrary.recognize(_buffer)
			_buffer.clear()
			prints(result._template_name, result._score)
			print("Gesturing for ", (Time.get_ticks_msec() - _start_gesture_time))
		else:
			_start_gesture_time = Time.get_ticks_msec()
			
	if event is InputEventMouseMotion && _gesturing:
		point_count += 1
		var current_position = get_viewport().get_mouse_position()
		_buffer.append(current_position)
		
		if point_count > 0:
			var delta_vector = current_position - previous_mouse_position
			#prints ("Mouse motion ",  delta_vector, delta_vector.length(), point_count)
			previous_mouse_position = current_position
			_trail_line.add_point(current_position)
			if (_trail_line.points.size() >= BUFFER_SIZE):
				_trail_line.remove_point(0)
		
		
		
	
