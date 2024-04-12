extends Node2D

var _recording_mode = false
var _points_count:int = 0
var _start_recording_time
var _random_hue
var _rng
var _points:Array[Vector2] = []
var _gesture_count = 0
@export var point_sprite:Sprite2D
@export var resampled_point:Sprite2D
@export var template_library:TemplateLibraryBehaviour
@export var vector_indicator:Line2D
@export var template_label:TemplateLabelBehaviour

# Called when the node enters the scene tree for the first time.
func _ready():
	_rng = RandomNumberGenerator.new() 
	_rng.seed = hash("demo")
	_rng.state = 8
	_rng.randf()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton: 
		_recording_mode = event.is_pressed()
		if _recording_mode:
			print("Starting recording points")
			_points_count = 0
			_start_recording_time = Time.get_ticks_msec()
			_random_hue = Color.from_hsv(_rng.randf(),  0.8, 0.8)
			_points.clear()
			_gesture_count += 1
		else:
			prints("Finished recording, %d points, took %s ms" % [_points_count, (Time.get_ticks_msec() - _start_recording_time)])
			var recongised_template = template_library.recognize(_points)
			print(recongised_template._template_name)
			var vectorisation = template_library._new_penny_pincher_vectorisation_v5(_points)
			
			var resampled_points =  vectorisation["points"]
			var center_point = Vector2.ZERO
			for resampled_vector_point in resampled_points:
				var cloned_resampled_point = resampled_point.duplicate()
				cloned_resampled_point.global_position = resampled_vector_point
				add_child(cloned_resampled_point)
				center_point = center_point + resampled_vector_point
			
			center_point = center_point / resampled_points.size()
			print(center_point)
			
			var cloned_label:TemplateLabelBehaviour = template_label.duplicate()
			add_child(cloned_label)
			#cloned_label.text = "%s (%2.2f%)" % [recongised_template._template_name, recongised_template._score]
			var percentage_match = (recongised_template._score / 16.0) * 100.0
			cloned_label.text = "%s (%0.1f %%)" % [recongised_template._template_name, percentage_match]
			cloned_label.position = center_point
			cloned_label.modulate = _random_hue
			
			var resampled_vectors = vectorisation["vectors"]
			var move_vectors_tweener = create_tween().set_parallel(true)
			for i in resampled_vectors.size():
				var vector = resampled_vectors[i]
				var corresponding_point = resampled_points[i]
				var cloned_vector_indicator:Line2D = vector_indicator.duplicate()
				add_child(cloned_vector_indicator)
				cloned_vector_indicator.global_position = corresponding_point
				cloned_vector_indicator.clear_points()
				cloned_vector_indicator.add_point(Vector2.ZERO)
				cloned_vector_indicator.add_point(Vector2.ZERO + (vector * 50))
				
				var final_vector_location = Vector2((i * 60) + 50, 80 * _gesture_count)
				
				move_vectors_tweener.tween_property(cloned_vector_indicator, 
				"position", 
				final_vector_location, 
				1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(1 + (i * 0.1))
				
				move_vectors_tweener.tween_property(cloned_vector_indicator, 
				"modulate", 
				_random_hue, 
				1.5).set_delay(1 + (i * 0.1))
			
	if _recording_mode and event is InputEventMouseMotion:
		var mouse_position =  get_viewport().get_mouse_position()
		var cloned_sprite:Sprite2D = point_sprite.duplicate()
		cloned_sprite.global_position = mouse_position
		cloned_sprite.modulate = _random_hue
		add_child(cloned_sprite)
		_points_count += 1
		_points.append(mouse_position)
