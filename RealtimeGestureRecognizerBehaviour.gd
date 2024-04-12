extends Node2D
const MIN_BUFFER_SIZE: int = 50
const MAX_BUFFER_SIZE: int = 200
const SEARCH_STEP_SIZE: int = 25
const PREDICT_SEARCH_STEP_SIZE: int = 15
const RECOGNITION_THRESHOLD = 14.5

var previous_mouse_position:Vector2
var _buffer:Array[Vector2] = []
var _last_mouse_movement

@export var _templateLibrary:TemplateLibraryBehaviour
@export var mandala: MandalaBehaviour

@onready var _trail_line: Line2D = $DrawingLine
@onready var _template_line: Line2D = $ShapeLine
@onready var _shape_particles: GPUParticles2D = $ShapeParticles
var _recording_mode = false

func _ready():
	pass


func _process(delta):
	if !_buffer.is_empty() && (Time.get_ticks_msec() - _last_mouse_movement) > 500:
		_buffer.clear()
		_trail_line.clear_points()
	
func _input(event):
	if event is InputEventMouseMotion:
		handle_mouse_motion_event(event)
	
	if !_recording_mode:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_SPACE:
				_recording_mode = true
				print("Record mode..., make the gesture, then chord a gesture mneomic")
			if event.keycode == KEY_ESCAPE:
				mandala.clear_core()
	else:
		if event is InputEventKey:
			if event.keycode == KEY_H:
				record_buffer_as("heart")
			elif event.keycode == KEY_S:
				record_buffer_as("star")
			elif event.keycode == KEY_E:
				record_buffer_as("eye")
			elif event.keycode == KEY_C:
				record_buffer_as("clone")
			elif event.keycode == KEY_F:
				record_buffer_as("fill_circle")
			elif event.keycode == KEY_M:
				record_buffer_as("move")
			elif event.keycode == KEY_ESCAPE:
				_recording_mode = false;
				_buffer.clear()
				_trail_line.clear_points()
				mandala.clear_core()
		

func mandala_command(command:String):
	if command == "heart":
		mandala.add_glyph("heart")
	if 	command == "star":
		mandala.add_glyph("star")
	if command == "eye":
		mandala.add_glyph("eye")
	if command == "spiral":
		mandala.add_glyph("spiral")
	if command == "clone":
		mandala.clone_core_outwards()
	if command == "move":
		mandala.move_core_outwards()
	if  command == "fill_circle":
		mandala.fill_inner_core()

func _render_shape_line(buffer_points: Array[Vector2], matched_shape_points:Array[Vector2]):
	_template_line.clear_points()

	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF

	
	for point in buffer_points:
		min_x = min(point.x, min_x)
		max_x = max(point.x, max_x)
		min_y = min(point.y, min_y)
		max_y = max(point.y, max_y)

	var x_span = max_x - min_x
	var y_span = max_y - min_y

	var max_span:float = max(x_span, y_span)
	var origin = buffer_points[0]
	
	var particles_tween = get_tree().create_tween()
	_shape_particles.emitting = true
	
	var delay = 0.05
	var delay_delta = 1.02
	_shape_particles.position = (matched_shape_points[0] * max_span) + origin
	for shape_point in matched_shape_points:
		var particle_position:Vector2 = (shape_point * max_span) + origin
		particles_tween.tween_property(_shape_particles, "position", particle_position, delay)
		delay *= delay_delta
		#_template_line.add_point(particle_position)
		
	particles_tween.tween_callback(_disable_particles)

func _disable_particles():
	_shape_particles.emitting = false
		
func _render_prediction_line(buffer_points: Array[Vector2], predicted_template_points: Array[Vector2], full_template_points: Array[Vector2]):
	# the template points are normalized, so let's move them to buffer points, and scale them by buffer points
	_template_line.clear_points()
	var buffer_origin = buffer_points[0]
	var buffer_end = buffer_points[-1]
	var buffer_vector = buffer_end.direction_to(buffer_origin)
	
	var predicted_template_origin = predicted_template_points[0]
	var predicted_template_end = predicted_template_points[-1]
	var predicted_vector = predicted_template_end.direction_to(predicted_template_origin)
	
	var scaling_vector = buffer_vector.direction_to(predicted_vector)
	 
	# get a vector from buffer start to end.
	# then scale the template by the same vector, and translate 
	
	for template_point in full_template_points:
		_template_line.add_point((template_point * 150) )

func _on_template_loader_on_templates_loaded():
	print("templates loaded")
		
func handle_mouse_motion_event(event):
	_last_mouse_movement = Time.get_ticks_msec()

	var current_position: Vector2 = get_viewport().get_mouse_position()
	_buffer.append(current_position)
	_trail_line.add_point(current_position)


	if (_trail_line.points.size() >= MAX_BUFFER_SIZE):
		_buffer.remove_at(0) # TODO - nasty, use a ring buffer for performance
		_trail_line.remove_point(0)

	# Too unstable for now
	## PREDICTion LOOP
	#if _buffer.size() > MIN_BUFFER_SIZE / 2:
		#var recognised = false;
		#var previous_start_index = _buffer.size()
#
		#for _buffer_search_size in range(MIN_BUFFER_SIZE + PREDICT_SEARCH_STEP_SIZE, MAX_BUFFER_SIZE, PREDICT_SEARCH_STEP_SIZE):
			#var start_index = _buffer.size() - _buffer_search_size
			#start_index  = max(0, start_index)
			#if previous_start_index == start_index:
				#break
#
			#previous_start_index = start_index
			#var sub_buffer = _buffer.slice(start_index, _buffer.size())
			#var results = _templateLibrary.predict(sub_buffer)
#
			#for result_key in results.keys():
				#if results[result_key] > 12:
					#prints("Prediction '%s': %5.2f" % [result_key, results[result_key]])
					#_render_prediction_line(sub_buffer, _templateLibrary.get_prediction_points(result_key), _templateLibrary.get_resampled_points(result_key))

		
	
	## DETECTION LOOP
	if !_recording_mode && _buffer.size() > MIN_BUFFER_SIZE:
		# iterate through the buffer in steps, presenting each to the recognizer
		# iterate from the latest 50, up to the latest 150
		# loop from 50 to 150
		# subtracting, the loop from the buffer size. if we're at the max buffer, quit
		# TODO don't do this every frame, only recognise every few frames

		var recognised = false;

		var previous_start_index = _buffer.size()

		for buffer_search_size in range(MIN_BUFFER_SIZE, MAX_BUFFER_SIZE, SEARCH_STEP_SIZE):
			# TRIM the buffer based on search buffer size, 
			# TODO use a circular buffer
			var start_index = _buffer.size() - buffer_search_size
			start_index = max(0, start_index)

			if previous_start_index == start_index:
				# we exhausted searching the buffer
				break

			previous_start_index = start_index
			var sub_buffer = _buffer.slice(start_index, _buffer.size())
			var result = _templateLibrary.recognize(sub_buffer)
			if (result._score > RECOGNITION_THRESHOLD):
				recognised = true
				prints(result._template_name, result._score)
				_buffer.clear()
				_trail_line.clear_points()
				_render_shape_line(sub_buffer, _templateLibrary.get_resampled_points(result._template_name))
				mandala_command(result._template_name)

			if recognised:
				break
	
func record_buffer_as(template_name):
	_recording_mode = false;
	_templateLibrary.add_template(template_name, _buffer, true)
	_buffer.clear()
	_trail_line.clear_points()
	print("Template ", template_name, " added")
