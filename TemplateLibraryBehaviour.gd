extends Node
class_name TemplateLibraryBehaviour

const TEMPLATE_POINT_SIZE = 17
const TEMPLATE_VECTORS_SIZE = 16

var _resampled_templates = {}
var _vector_points = {}
var _predict_vector_points = {}
var _predict_resampled_points = {}

signal on_new_template_added(template_name:String, points:Array[Vector2])
	
func add_template(name: String, points:Array[Vector2], requires_persistance = false):
	var resampled_points_and_vectors: Dictionary = _new_penny_pincher_vectorisation_v5(points)

	if !_resampled_templates.has(name):
		_resampled_templates[name] = []
		_vector_points[name] = []

	_resampled_templates[name].append(resampled_points_and_vectors["points"])
	_vector_points[name].append(resampled_points_and_vectors["vectors"])

	var half_length_points: Array[Vector2] = points.slice(0, (points.size() / 2))
	var half_length_points_and_vectors: Dictionary = _new_penny_pincher_vectorisation_v5(half_length_points)

	_predict_vector_points[name] = half_length_points_and_vectors["vectors"]
	_predict_resampled_points[name] = half_length_points_and_vectors["points"]
	
	if requires_persistance:
		emit_signal("on_new_template_added", name, points)
		

	
func get_resampled_points(template_name:String) -> Array[Vector2]:
	return _resampled_templates[template_name][0]
	
func get_vector_points(template_name:String) -> Array[Vector2]:
	return _vector_points[template_name][0]
	
func get_prediction_points(template_name:String) -> Array[Vector2]:
	return _predict_resampled_points[template_name]

func get_prediction_vectors(template_name: String) -> Array[Vector2]:
	return _predict_vector_points[template_name]
	
func recognize(point_stream:Array[Vector2]) -> RecognitionResult:

	var resampled_point_stream: Dictionary = _new_penny_pincher_vectorisation_v5(point_stream)
	var resampled_vectors                  = resampled_point_stream["vectors"]
	var best_similarity:float  = -INF
	var best_match_template :String

	for template_key in _vector_points.keys():

		var template_vectors_array = _vector_points[template_key]
	
		for template_vectors in template_vectors_array:
			var template_similarity:float = 0
			
			for i in range(TEMPLATE_VECTORS_SIZE):
				var stream_vector:Vector2 = resampled_vectors[i]
				var template_vector:Vector2 = template_vectors[i]

				var dot_product: float = stream_vector.dot(template_vector)
				template_similarity += dot_product

			if (template_similarity > best_similarity):
				best_similarity = template_similarity
				best_match_template = template_key


	return RecognitionResult.new(best_match_template, best_similarity)

## Look at all HALF templates, and see if the user is in the middle of a gesture
## returns a dictionary of each template name and the score
func predict(point_stream: Array[Vector2]) -> Dictionary:

	var resampled_point_steam: Dictionary = _new_penny_pincher_vectorisation_v5(point_stream)
	var resampled_vectors = resampled_point_steam["vectors"]
	var scoring: Dictionary = {}

	for prediction_template_key in _predict_vector_points.keys():
		var template_vectors = _predict_vector_points[prediction_template_key]
		var template_similarity:float = 0

		for i in range(TEMPLATE_VECTORS_SIZE):
			var stream_vector:Vector2 = resampled_vectors[i]
			var template_vector:Vector2 = template_vectors[i]

			var dot_product: float = stream_vector.dot(template_vector)
			template_similarity += dot_product

		scoring[prediction_template_key] = template_similarity

	return scoring

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
				# Only move to the next point if the distance between points is smaller than the step size,
				# and we're not at the end of the line to resample
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
