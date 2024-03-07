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

		


func _on_template_loader_on_templates_loaded():
	print("templates loaded, getting one to render")
	var template_points = _templateLibrary.get_raw_template_points("triangle")
	#
	#for point in template_points:
		#_trail_line.add_point(point)

	var resampled_points = _templateLibrary.get_resampled_points("triangle")
	var vector_points = _templateLibrary.get_vector_points("triangle")
	
	for point_index in range(0, resampled_points.size() - 1):
		var point = resampled_points[point_index]
		var vector = vector_points[point_index]
		
		_template_line.add_point(point * 1)
		var vector_indicator = Line2D.new()
		vector_indicator.width = 2
		vector_indicator.add_point(point)
		vector_indicator.add_point(point + (vector * 20))
		_template_line.add_child(vector_indicator)
		
		
		
	
