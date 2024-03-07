extends Node
class_name TemplateLibraryBehaviour

const TEMPLATE_POINT_SIZE = 17
const TEMPLATE_VECTORS_SIZE = 16
@export var some_var: int

var _templates = {}
var _resampled_templates = {}
var _vector_points = {}

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func add_template(name: String, points:Array[Vector2]):
	_templates[name] = points
	var resampled_points_and_vectors = _new_penny_pincher_vectorisation_v5(points)

	_resampled_templates[name] = resampled_points_and_vectors["points"]
	_vector_points[name] = resampled_points_and_vectors["vectors"]

	#prints("Resampled points for", name, "points", _resampled_templates[name].size())
	
	
func get_raw_template_points(template_name:String) -> Array[Vector2]:
	return _templates[template_name]
	
func get_resampled_points(template_name:String) -> Array[Vector2]:
	return _resampled_templates[template_name]
	
func get_vector_points(template_name:String) -> Array[Vector2]:
	return _vector_points[template_name]
	
func recognize(point_stream:Array[Vector2]) -> RecognitionResult:
	var start_recognize_time = Time.get_ticks_usec()
	
	var resampled_point_steam =  _new_penny_pincher_vectorisation_v5(point_stream)
	var resampled_vectors = resampled_point_steam["vectors"]
	var best_similarity:float = -INF
	var best_match_template :String

	if resampled_vectors.size() < TEMPLATE_VECTORS_SIZE:
		prints("Resampled incorrectly", resampled_vectors.size())
		prints("\nVectors")
		prints(resampled_vectors)
		prints("\nPoints")
		prints(resampled_point_steam["points"])
		prints("\nOriginal Point Stream", point_stream.size())
		prints(point_stream)
		_new_penny_pincher_vectorisation_v5(point_stream, true)
		
	for template_key in _vector_points.keys():
		var template_vectors = _vector_points[template_key]
		var template_similarity:float = 0

		for i in range(TEMPLATE_VECTORS_SIZE):
			var stream_vector:Vector2 = resampled_vectors[i]
			var template_vector:Vector2 = template_vectors[i]

			var dot_product: float = stream_vector.dot(template_vector)
			template_similarity += dot_product

		#prints("Testing ", template_key, "similarity", template_similarity)
		if (template_similarity > best_similarity):
			best_similarity = template_similarity
			best_match_template = template_key

	var end_recognize_time = Time.get_ticks_usec()
	#prints("\nTemplate", best_match_template, "Score", best_similarity, "Testing took (us)", (end_recognize_time-start_recognize_time))
	
	
	return RecognitionResult.new(best_match_template, best_similarity)
	

func _resample_between_points_dollar_one_style(template_name:String, original_points:Array[Vector2]) -> Array[Vector2]:
	var path_length: float = _path_length(original_points)
	var resample_distance_step: float = path_length / (TEMPLATE_POINT_SIZE - 1)
	var accumlated_path_distance: int = 0
	var resampled_points: Array[Vector2] = []
	var previous_point: Vector2  = original_points[0]
	var current_point_index: int = 1

	prints("Resampling ", template_name, "points", original_points.size(), "path length", path_length)
	resampled_points.append(original_points[0])
	
	while current_point_index < (original_points.size() - 1):
		var current_point:Vector2 = original_points[current_point_index]
		var delta:Vector2 = current_point - previous_point
		var distance_between_points:float = delta.length() 
		
		if (accumlated_path_distance + distance_between_points) >= resample_distance_step:
			var span: float = (resample_distance_step - accumlated_path_distance) / distance_between_points
			var new_point: Vector2 = previous_point + (span * delta)

			accumlated_path_distance = 0
			previous_point = new_point
			resampled_points.append(new_point)
		else:
			current_point_index += 1
			previous_point = current_point
			accumlated_path_distance += distance_between_points
	
	if resampled_points.size() < TEMPLATE_POINT_SIZE:
		resampled_points.append(previous_point)
		
	return resampled_points

func _new_penny_pincher_vectorisation_v3(points: Array[Vector2]) -> Dictionary:
	var start_time:int = Time.get_ticks_usec()

	var path_length: float = _path_length(points);
	# "I" - if we want 16 points, the step size needs to be divided by POINTS - 1, this yields POINTS - 1 vectors
	var step_size : float  = path_length / (TEMPLATE_POINT_SIZE - 1)
	# "D"
	var temporary_path_accumulator: float = 0
	var full_path_accumulator: float = 0
	var new_points:Array[Vector2] = []
	var new_vectors:Array[Vector2] = []

#	prints("Path length", path_length, "step_size", step_size, "Number of original points", points.size())

	var previous_resampled_point: Vector2 = points[0] 
	var previous_point: Vector2 = points[0]
	new_points.append(points[0])
	var point_index = 1;

	var path_unresolved:bool = true
	
	while path_unresolved:
		var current_point = points[point_index]
#		prints(point_index, " - location", current_point, " ", full_path_accumulator)
		# d
		var delta:Vector2 = current_point - previous_point
		var distance_between_points:float = delta.length()

		if temporary_path_accumulator + distance_between_points > step_size || point_index == points.size() - 1:
			#we've gone past the step size, we need to add a point
			# somewhere between previous point and current point
			var over_step: float = step_size - temporary_path_accumulator
			var new_point: Vector2 = previous_point + delta * (over_step) / distance_between_points

			temporary_path_accumulator = 0
			full_path_accumulator += over_step

			var resampled_vector: Vector2 = previous_resampled_point.direction_to(new_point).normalized()

			previous_point = new_point
			previous_resampled_point = new_point
			new_points.append(new_point)
			new_vectors.append(resampled_vector)

			point_index += 1
		else:
			full_path_accumulator += distance_between_points
			temporary_path_accumulator += distance_between_points
			previous_point = current_point
			point_index += 1

		path_unresolved = (full_path_accumulator < path_length && point_index < points.size())

	prints("New points size", new_points.size())
	prints("New vectors size", new_vectors.size())

	var end_time:int = Time.get_ticks_usec()

	prints("Resampled in", (end_time - start_time), "us")

	return {"points": new_points, "vectors": new_vectors}

func _new_penny_pincher_vectorisation_v4(points: Array[Vector2], debug_printing:bool = false) -> Dictionary:
	var start_time:int = Time.get_ticks_usec()

	var path_length: float = _path_length(points);
	# "I" - if we want 16 points, the step size needs to be divided by POINTS - 1, this yields POINTS - 1 vectors
	var step_size : float  = path_length / (TEMPLATE_POINT_SIZE - 1)
	# "D"
	var temporary_path_accumulator: float = 0
	var full_path_accumulator: float = 0
	var new_points:Array[Vector2] = []
	var new_vectors:Array[Vector2] = []

	if debug_printing:
		prints("Path length", path_length, "step_size", step_size, "Number of original points", points.size())

	var previous_resampled_point: Vector2 = points[0]
	var previous_point: Vector2 = points[0]
	new_points.append(points[0])

	for point_index in range(1, points.size()):
		var current_point: Vector2 = points[point_index]
		
		# d
		var delta:Vector2 = current_point - previous_point
		var distance_between_points:float = delta.length()

		if temporary_path_accumulator + distance_between_points > step_size || point_index >= points.size() - 1:
			#we've gone past the step size, we need to add a point
			# somewhere between previous point and current point
			if (distance_between_points > step_size):
				prints("WARNING! distance between points is bigger than step size %5.2f %5.2f" % [distance_between_points, step_size] )
				# TODO, we need to create multiple points
				# work out where it should be placed, set this new point as the previous point.... don't increment

			var over_step: float = step_size - temporary_path_accumulator
			var new_point: Vector2 = previous_point + delta * (over_step) / distance_between_points

			var temporary_path_accumulator_before_reset = temporary_path_accumulator + distance_between_points
			temporary_path_accumulator = 0
			full_path_accumulator += over_step

			var resampled_vector: Vector2 = previous_resampled_point.direction_to(new_point).normalized()

			previous_point = new_point
			previous_resampled_point = new_point
			new_points.append(new_point)
			new_vectors.append(resampled_vector)
			
			if debug_printing:
				prints(point_index, " - location", current_point, " accumulator ", full_path_accumulator, "temp acc", temporary_path_accumulator_before_reset, "distance between points", distance_between_points,  " ADD NEW POINT #", new_points.size())
		else:
				
			full_path_accumulator += distance_between_points
			temporary_path_accumulator += distance_between_points
			previous_point = current_point
			
			if debug_printing:
				prints(point_index, " - location", current_point, " ", full_path_accumulator, " stepping")

	#prints("New points size", new_points.size())
	#prints("New vectors size", new_vectors.size())
	if debug_printing:
		prints("Fininished resample - accumulator", full_path_accumulator)

	var end_time:int = Time.get_ticks_usec()

	#prints("Resampled in", (end_time - start_time), "us")

	return {"points": new_points, "vectors": new_vectors}

func _new_penny_pincher_vectorisation_v5(points: Array[Vector2], debug_printing:bool = false) -> Dictionary:
	var start_time:int = Time.get_ticks_usec()

	var path_length: float = _path_length(points);
	# "I" - if we want 16 points, the step size needs to be divided by POINTS - 1, this yields POINTS - 1 vectors
	var step_size : float  = path_length / (TEMPLATE_POINT_SIZE - 1)
	# "D"
	var temporary_path_accumulator: float = 0
	var full_path_accumulator: float = 0
	var new_points:Array[Vector2] = []
	var new_vectors:Array[Vector2] = []

	if debug_printing:
		prints("Path length", path_length, "step_size", step_size, "Number of original points", points.size())

	var previous_resampled_point: Vector2 = points[0]
	var previous_point: Vector2 = points[0]
	new_points.append(points[0])

	var point_index = 1
	var current_point = points[point_index]
	var path_fully_resampled = false

	while !path_fully_resampled:
		# d
		var delta:Vector2 = current_point - previous_point
		var distance_between_points:float = delta.length()

		if temporary_path_accumulator + distance_between_points > step_size || point_index >= points.size() - 1:
			#we've gone past the step size, we need to add a point
			# somewhere between previous point and current point

			var over_step: float = step_size - temporary_path_accumulator
			var new_point: Vector2 = previous_point + delta * (over_step) / distance_between_points

			var temporary_path_accumulator_before_reset = temporary_path_accumulator + distance_between_points
			temporary_path_accumulator = 0
			full_path_accumulator += over_step

			var resampled_vector: Vector2 = previous_resampled_point.direction_to(new_point).normalized()

			previous_point = new_point
			previous_resampled_point = new_point
			new_points.append(new_point)
			new_vectors.append(resampled_vector)

			if (distance_between_points <= step_size && point_index < points.size() - 1):
				# Only move to the next point, if the distance between points is smaller than the step size, and we're not at the
				# end of the line to resample
				point_index += 1
				current_point = points[point_index]


			if debug_printing:
				prints(point_index, " - location", current_point, " accumulator ", full_path_accumulator, "temp acc", temporary_path_accumulator_before_reset, "distance between points", distance_between_points,  " ADD NEW POINT #", new_points.size())
		else:

			full_path_accumulator += distance_between_points
			temporary_path_accumulator += distance_between_points
			previous_point = current_point
			point_index += 1
			current_point = points[point_index]

			if debug_printing:
				prints(point_index, " - location", current_point, " ", full_path_accumulator, " stepping")

		path_fully_resampled = full_path_accumulator >= path_length

				#prints("New vectors size", new_vectors.size())
	if debug_printing:
		prints("Fininished resample - accumulator", full_path_accumulator)

	var end_time:int = Time.get_ticks_usec()

	#prints("Resampled in", (end_time - start_time), "us")

	return {"points": new_points, "vectors": new_vectors}

func _path_length(path_points: Array[Vector2]) -> float:
	var accumulated_length:float = 0
	var previous_point: Vector2 = path_points[0]
	
	for index in range(1, path_points.size()):
		var point: Vector2 = path_points[index]
		accumulated_length += previous_point.distance_to(point)
		previous_point = point
		
	return accumulated_length  
