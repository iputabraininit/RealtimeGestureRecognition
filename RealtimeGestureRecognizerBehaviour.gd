extends Node2D
const MIN_BUFFER_SIZE = 40
const MAX_BUFFER_SIZE = 150 
var point_count = 0 
# Called when the node enters the scene tree for the first time.
var previous_mouse_position:Vector2
var _buffer:Array[Vector2] = []

@export var _templateLibrary:TemplateLibraryBehaviour

@onready var _trail_line: Line2D = $Line2D
@onready var _template_line: Line2D = $TemplateLine

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if event is InputEventMouseMotion:

		var current_position: Vector2 = get_viewport().get_mouse_position()
		_buffer.append(current_position)
		_trail_line.add_point(current_position)


		if (_trail_line.points.size() >= MAX_BUFFER_SIZE):
			_buffer.remove_at(0) # TODO - nasty, use a ring buffer for performance
			_trail_line.remove_point(0)

		
		if _buffer.size() > MIN_BUFFER_SIZE:
			# TODO don't do this every frame, only recognise every few frames
			var result = _templateLibrary.recognize(_buffer)
			if (result._score > 14):
				prints(result._template_name, result._score)
				_buffer.clear()
				_trail_line.clear_points()
		


func _on_template_loader_on_templates_loaded():
	print("templates loaded")
	#var template_points = _templateLibrary.get_raw_template_points("triangle")
	##
	##for point in template_points:
		##_trail_line.add_point(point)
#
	#var resampled_points = _templateLibrary.get_resampled_points("triangle")
	#var vector_points = _templateLibrary.get_vector_points("triangle")
	#
	#for point_index in range(0, resampled_points.size() - 1):
		#var point = resampled_points[point_index]
		#var vector = vector_points[point_index]
		#
		#_template_line.add_point(point * 1)
		#var vector_indicator = Line2D.new()
		#vector_indicator.width = 2
		#vector_indicator.add_point(point)
		#vector_indicator.add_point(point + (vector * 20))
		#_template_line.add_child(vector_indicator)
		
		
		
	
